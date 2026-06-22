require 'tempfile'
require 'aws-sdk-s3'
require 'rubyXL'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'

class UrnListImporterJob < ApplicationJob
  class AlreadyImported < StandardError; end

  discard_on ActiveJob::DeserializationError
  discard_on AlreadyImported

  retry_on Aws::S3::Errors::ServiceError

  # rubocop:disable Metrics/AbcSize
  def perform(urn_list)
    raise AlreadyImported unless urn_list.pending?

    downloader = AttachedFileDownloader.new(urn_list.excel_file)
    downloader.download!

    rows = UrnLists::ReadExcel.new(file_path: downloader.temp_file.path).call
    count = UrnLists::ImportCustomers.new(rows: rows).call

    workbook_temp_file = build_workbook_temp_file(urn_list)
    remove_published_column(urn_list, workbook_temp_file.path)

    urn_list.update!(
      aasm_state: :processed,
      completed_at: Time.current,
      processed_count: count
    )
  rescue Aws::S3::Errors::ServiceError
    raise
  rescue UrnLists::ReadExcel::InvalidFormat
    mark_failed!(urn_list)
    raise
  rescue StandardError => e
    mark_failed!(urn_list) if urn_list.persisted? && urn_list.pending?
    raise e
  ensure
    cleanup_downloader_temp_file(downloader&.temp_file)
    cleanup_downloader_temp_file(workbook_temp_file)
  end
  # rubocop:enable Metrics/AbcSize

  private

  def build_workbook_temp_file(urn_list)
    file = Tempfile.new(['urn_list_workbook', '.xlsx'])
    file.binmode
    file.write(urn_list.excel_file.download)
    file.flush
    file.rewind
    file
  end

  def cleanup_downloader_temp_file(file)
    return unless file

    file.close unless file.closed?
    file.unlink
  end

  def remove_published_column(urn_list, path)
    workbook = RubyXL::Parser.parse(path)
    worksheet = workbook[0]
    row_count = worksheet.sheet_data.rows.size

    id_and_remove_non_publish_rows(worksheet, row_count, 1)

    worksheet.delete_column(4)

    file_name = urn_list.excel_file.filename
    workbook.write(path)
    urn_list.excel_file.purge
    urn_list.excel_file.attach(io: File.open(path), filename: file_name)
  end

  def id_and_remove_non_publish_rows(worksheet, row_count, row_num)
    while row_num <= row_count
      row = worksheet[row_num]
      break if row.nil?

      row_num += 1 unless delete_non_publish_row(worksheet, row_num, row)
    end
  end

  def delete_non_publish_row(worksheet, row_num, row)
    value = row[4].value if row[4]
    value = value.upcase if value.is_a? String
    value = ActiveModel::Type::Boolean.new.cast(value)
    return unless value == false

    worksheet.delete_row(row_num)
    true
  end

  def mark_failed!(urn_list, processed_count: 0)
    urn_list.update!(
      aasm_state: :failed,
      completed_at: Time.current,
      processed_count: processed_count
    )
  end
end
