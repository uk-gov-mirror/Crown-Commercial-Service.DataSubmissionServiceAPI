require 'net/http'
require 'uri'
require 'json'

module UrnLists
  class ApiClient
    class ApiError < StandardError; end

    def fetch_customers
      token = fetch_access_token
      fetch_urn_list(token)
    end

    def fetch_inactive_customers
      token = fetch_access_token
      fetch_inactive_urn_list(token)
    end

    private

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

    def fetch_urn_list(token)
      base_url = 'https://apim.crowncommercial.gov.uk/website-data/manual/paths/invoke/%5Batt%5D.%5Bvw_RMIActiveURNList%5D/'
      params = {
        'api-version' => '2016-10-01',
        'sp' => '/triggers/manual/run',
        'sv' => '1.0',
        'filter' => "Published eq 'True'"
      }

      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)

      request = Net::HTTP::Get.new(uri.to_s)
      request['Authorization'] = "Bearer #{token}"
      request['Accept'] = 'application/json'

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      raise ApiError, "Failed to fetch URN list: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      rows = JSON.parse(response.body)
      validate_rows!(rows)
      rows
    end

    def fetch_inactive_urn_list(token)
      base_url = 'https://apim.crowncommercial.gov.uk/website-data/manual/paths/invoke/%5Batt%5D.%5Bvw_RMIInactiveURNList%5D/'
      params = {
        'api-version' => '2016-10-01',
        'sp' => '/triggers/manual/run',
        'sv' => '1.0'
      }

      uri = URI(base_url)
      uri.query = URI.encode_www_form(params)
      
      request = Net::HTTP::Get.new(uri.to_s)
      request['Authorization'] = "Bearer #{token}"
      request['Accept'] = 'application/json'

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
        http.request(request)
      end

      raise ApiError, "Failed to fetch inactive URN list: #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      rows = JSON.parse(response.body)
      validate_rows!(rows)
      rows
    end

    def validate_rows!(rows)
      return if rows.is_a?(Array) && rows.all? { |row| row.is_a?(Hash) }

      raise ApiError, 'Invalid URN list format: expected an array of objects'
    end
  end
end
