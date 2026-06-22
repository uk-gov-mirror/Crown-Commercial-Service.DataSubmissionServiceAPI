require 'csv'
require 'tempfile'
require 'shellwords'

module UrnLists
  class ReadExcel
    class InvalidFormat < StandardError; end

    REQUIRED_COLUMNS = ['URN', 'CustomerName', 'PostCode', 'Sector', 'Published'].freeze

    def initialize(file_path:)
      @file_path = file_path
    end

    def call
      convert_to_csv
      rows_from_csv
    ensure
      cleanup_csv_temp_file
    end

    private

    attr_reader :file_path

    def convert_to_csv
      command = "in2csv --sheet=\"Customers\" --locale=en_GB --blanks --skipinitialspace #{file_path}"
      command += " | csvcut -c 'URN,CustomerName,PostCode,Sector,Published'"
      command += " > \"#{csv_temp_file.path}\""

      result = Ingest::CommandRunner.new(command).run!

      raise InvalidFormat if result.stderr.any? { |s| s.include?('Error') }
    end

    def rows_from_csv
      rows = []

      CSV.foreach(csv_temp_file, headers: true) do |row|
        raise InvalidFormat unless (row.headers & REQUIRED_COLUMNS) == REQUIRED_COLUMNS

        rows << Customer.new(
          name: row['CustomerName'],
          urn: row['URN'].to_i,
          postcode: row['PostCode'],
          sector: (row['Sector'] == 'Central Government' ? :central_government : :wider_public_sector),
          deleted: false,
          published: (row['Published'] != 'False')
        )
      end

      rows
    end

    def csv_temp_file
      @csv_temp_file ||= Tempfile.new('customer')
    end

    def cleanup_csv_temp_file
      return unless @csv_temp_file

      @csv_temp_file.close unless @csv_temp_file.closed?
      @csv_temp_file.unlink
    end
  end
end
