require 'net/http'
require 'uri'
require 'json'

module UrnLists
  class ApiClient
    class ApiError < StandardError; end

    TOP_COUNT = 10_000

    def fetch_rows
      fetch_paginated_rows(
        base_url: active_urns_url,
        params: {
          'api-version' => '2016-10-01',
          'sp' => '/triggers/manual/run',
          'sv' => '1.0'
        },
        error_message: 'Failed to fetch URN list'
      )
    end

    def fetch_inactive_rows
      fetch_paginated_rows(
        base_url: inactive_urns_url,
        params: {
          'api-version' => '2016-10-01',
          'sp' => '/triggers/manual/run',
          'sv' => '1.0'
        },
        error_message: 'Failed to fetch inactive URN list'
      )
    end

    private

    # rubocop:disable Metrics/AbcSize
    def fetch_paginated_rows(base_url:, params:, error_message:)
      token = fetch_access_token

      all_rows = []
      skip = 0

      loop do
        rows = fetch_page(
          token: token,
          base_url: base_url,
          params: params,
          top_count: TOP_COUNT,
          skip: skip,
          error_message: error_message
        )

        break if rows.empty?

        all_rows.concat(rows)
        break if rows.size < TOP_COUNT - 1

        skip += TOP_COUNT
      end

      all_rows.map { |row| row['URN'] || row['urn'] }.compact

      all_rows
    end

    # rubocop:disable Metrics/ParameterLists
    def fetch_page(token:, base_url:, params:, top_count:, skip:, error_message:)
      uri = URI(base_url)

      query_params = {
        'SkipCount' => skip,
        'TopCount' => top_count
      }.merge(params)

      uri.query = URI.encode_www_form(query_params)

      request = Net::HTTP::Get.new(uri.to_s)
      request['Authorization'] = "Bearer #{token}"

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      raise ApiError, "#{error_message}: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      rows = body.is_a?(Hash) ? body.fetch('value') : body
      validate_rows!(rows)
      rows
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Metrics/AbcSize

    def fetch_access_token
      uri = URI.parse(ENV.fetch('MDM_API_TOKEN_URL'))

      response = Net::HTTP.post_form(uri, {
                                       grant_type: 'client_credentials',
        client_id: ENV.fetch('MDM_API_CLIENT_ID'),
        client_secret: ENV.fetch('MDM_API_CLIENT_SECRET'),
        scope: ENV.fetch('MDM_API_SCOPE')
                                     })

      raise ApiError, "Failed to fetch access token: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      body.fetch('access_token')
    end

    def validate_rows!(rows)
      return if rows.is_a?(Array) && rows.all? { |row| row.is_a?(Hash) }

      raise ApiError, 'Invalid URN list format: expected an array of objects'
    end

    def active_urns_url
      'https://apim.crowncommercial.gov.uk/mdm-api-service/spend-data/%5Bdbo%5D.%5BRMIActiveURNList%5D/'
    end

    def inactive_urns_url
      'https://apim.crowncommercial.gov.uk/mdm-api-service/spend-data/%5Bdbo%5D.%5BRMIInActiveURNList%5D/'
    end
  end
end
