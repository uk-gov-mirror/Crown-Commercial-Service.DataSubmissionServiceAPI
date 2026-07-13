require 'rails_helper'

RSpec.describe UrnListImporterJob do
  describe '#perform' do
    let(:urn_list) do
      create(
        :urn_list,
        source: 'manual_upload',
        aasm_state: :pending
      )
    end

    let(:download_tempfile) do
      file = Tempfile.new(['test', '.xlsx'])
      file.binmode
      file.write('dummy-content')
      file.flush
      file.rewind
      file
    end

    let(:workbook_tempfile) do
      file = Tempfile.new(['workbook', '.xlsx'])
      file.binmode
      file.write('dummy-workbook-content')
      file.flush
      file.rewind
      file
    end

    let(:downloader) do
      double(
        'AttachedFileDownloader',
        download!: true,
        temp_file: download_tempfile
      )
    end

    let(:rows) do
      [
        Customer.new(
          urn: 10009655,
          name: 'Crown Commercial Service',
          postcode: 'L3 9PP',
          sector: 'central_government',
          deleted: false,
          published: true
        ),
        Customer.new(
          urn: 10009656,
          name: 'Another Organisation',
          postcode: 'AB1 2CD',
          sector: 'wider_public_sector',
          deleted: false,
          published: true
        )
      ]
    end

    let(:read_excel_service) { double('UrnLists::ReadExcel', call: rows) }
    let(:import_customers_service) { double('UrnLists::ImportCustomers', call: rows.count) }

    before do
      allow(AttachedFileDownloader).to receive(:new).with(urn_list.excel_file).and_return(downloader)
      allow(UrnLists::ReadExcel).to receive(:new)
        .with(file_path: download_tempfile.path)
        .and_return(read_excel_service)
      allow(UrnLists::ImportCustomers).to receive(:new)
        .with(rows: rows)
        .and_return(import_customers_service)
      allow_any_instance_of(described_class).to receive(:build_workbook_temp_file)
        .with(urn_list).and_return(workbook_tempfile)
      allow_any_instance_of(described_class).to receive(:remove_published_column).with(urn_list, workbook_tempfile.path)
      allow_any_instance_of(described_class).to receive(:cleanup_downloader_temp_file)
    end

    after do
      [download_tempfile, workbook_tempfile].each do |file|
        next if file.closed?

        file.close
        file.unlink
      rescue StandardError
        nil
      end
    end

    it 'downloads the file, processes it, and updates the URN list record' do
      described_class.perform_now(urn_list)

      expect(AttachedFileDownloader).to have_received(:new).with(urn_list.excel_file)
      expect(downloader).to have_received(:download!)
      expect(UrnLists::ReadExcel).to have_received(:new).with(file_path: download_tempfile.path)
      expect(read_excel_service).to have_received(:call)
      expect(UrnLists::ImportCustomers).to have_received(:new).with(rows: rows)
      expect(import_customers_service).to have_received(:call)

      urn_list.reload
      expect(urn_list).to be_processed
      expect(urn_list.completed_at).to be_present
      expect(urn_list.processed_count).to eq(rows.count)
    end

    it 'raises AlreadyImported if the URN list is not pending' do
      urn_list.update!(aasm_state: :processed)

      expect(AttachedFileDownloader).not_to receive(:new)

      described_class.perform_now(urn_list)

      expect(urn_list.reload).to be_processed
    end

    it 'marks the URN list as failed when the spreadsheet is invalid' do
      bad_read_excel = double('UrnLists::ReadExcel')
      allow(bad_read_excel).to receive(:call).and_raise(UrnLists::ReadExcel::InvalidFormat)
      allow(UrnLists::ReadExcel).to receive(:new).and_return(bad_read_excel)

      expect do
        described_class.perform_now(urn_list)
      end.to raise_error(UrnLists::ReadExcel::InvalidFormat)

      urn_list.reload
      expect(urn_list).to be_failed
      expect(urn_list.completed_at).to be_present
      expect(urn_list.processed_count).to eq(0)
    end

    it 'retries the job when a transient S3 error occurs' do
      bad_downloader = double('AttachedFileDownloader')
      allow(bad_downloader).to receive(:download!).and_raise(Aws::S3::Errors::ServiceError.new(nil, 'S3 error'))
      allow(AttachedFileDownloader).to receive(:new).and_return(bad_downloader)

      urn_list.reload
      expect(urn_list).to be_pending
      expect(urn_list.completed_at).to be_nil
    end

    it 'marks the URN list as failed for unexpected errors' do
      bad_importer = double('UrnLists::ImportCustomers')
      allow(bad_importer).to receive(:call).and_raise(StandardError.new('Unexpected error'))
      allow(UrnLists::ImportCustomers).to receive(:new).and_return(bad_importer)

      expect do
        described_class.perform_now(urn_list)
      end.to raise_error(StandardError)

      urn_list.reload
      expect(urn_list).to be_failed
      expect(urn_list.completed_at).to be_present
      expect(urn_list.processed_count).to eq(0)
    end
  end

  describe 'private helper methods' do
    let(:job) { described_class.new }

    describe '#build_workbook_temp_file' do
      let(:urn_list) do
        create(:urn_list, source: 'manual_upload', aasm_state: :pending)
      end

      it 'writes the attached workbook to a tempfile' do
        tempfile = job.send(:build_workbook_temp_file, urn_list)

        expect(File.exist?(tempfile.path)).to be true
        expect(File.binread(tempfile.path)).to eq(urn_list.excel_file.download)
      ensure
        tempfile&.close
        tempfile&.unlink
      end
    end

    describe '#cleanup_downloader_temp_file' do
      it 'closes and deletes the tempfile' do
        file = Tempfile.new(['cleanup_test', '.xlsx'])
        path = file.path

        job.send(:cleanup_downloader_temp_file, file)

        expect(file.closed?).to be true
        expect(File.exist?(path)).to be false
      end

      it 'handles nil temp file' do
        expect { job.send(:cleanup_downloader_temp_file, nil) }.not_to raise_error
      end
    end

    describe '#delete_non_publish_row' do
      it 'deletes rows where published is false' do
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        worksheet.add_cell(0, 0, 'URN')
        worksheet.add_cell(0, 4, 'Published')

        worksheet.add_cell(1, 0, '10009655')
        worksheet.add_cell(1, 4, 'False')

        result = job.send(:delete_non_publish_row, worksheet, 1, worksheet[1])

        expect(result).to be true
        expect(worksheet[1]).to be_nil
      end

      it 'does not delete rows where published is true' do
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        worksheet.add_cell(0, 0, 'URN')
        worksheet.add_cell(0, 4, 'Published')

        worksheet.add_cell(1, 0, '10009655')
        worksheet.add_cell(1, 4, 'True')

        result = job.send(:delete_non_publish_row, worksheet, 1, worksheet[1])

        expect(result).to be_nil
        expect(worksheet[1]).not_to be_nil
      end
    end

    describe '#id_and_remove_non_publish_rows' do
      it 'iterates through rows and deletes non-published rows' do
        workbook = RubyXL::Workbook.new
        worksheet = workbook[0]

        worksheet.add_cell(0, 0, 'URN')
        worksheet.add_cell(0, 4, 'Published')

        # Published row
        worksheet.add_cell(1, 0, '10009655')
        worksheet.add_cell(1, 4, 'True')

        # Non-published row
        worksheet.add_cell(2, 0, '10009656')
        worksheet.add_cell(2, 4, 'False')

        row_count = worksheet.sheet_data.rows.size

        job.send(:id_and_remove_non_publish_rows, worksheet, row_count, 1)

        remaining_urns = worksheet.sheet_data.rows.compact.map { |row| row[0].value }

        expect(remaining_urns).to include('10009655')
        expect(remaining_urns).not_to include('10009656')
      end
    end

    describe '#remove_published_column' do
      let(:urn_list) do
        create(:urn_list, filename: 'customers_test.xlsx')
      end
      it 'removes the Published column from the workbook' do
        tempfile = job.send(:build_workbook_temp_file, urn_list)

        job.send(:remove_published_column, urn_list, tempfile.path)

        rewritten = Tempfile.new(['rewritten', '.xlsx'])
        rewritten.binmode
        rewritten.write(urn_list.excel_file.download)
        rewritten.flush
        rewritten.rewind

        workbook = RubyXL::Parser.parse(rewritten.path)
        worksheet = workbook[0]

        header_values = worksheet[0].cells.map(&:value)
        expect(header_values).not_to include('Published')
      ensure
        tempfile&.close
        tempfile&.unlink
        rewritten&.close
        rewritten&.unlink
      end
    end
  end
end
