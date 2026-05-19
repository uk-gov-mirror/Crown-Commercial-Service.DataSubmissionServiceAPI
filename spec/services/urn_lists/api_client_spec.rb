require 'rails_helper'

RSpec.describe UrnLists::ApiClient do
  describe '#fetch_customers' do
    before do
      stub_request(:post, 'https://example.com/oauth/token')
        .with(
          body: { 'client_id' => 'test_client_id', 'client_secret' => 'test_client_secret',
'grant_type' => 'client_credentials', 'scope' => 'test_scope' },
          headers: {
            'Accept' => '*/*',
           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
           'Content-Type' => 'application/x-www-form-urlencoded',
           'Host' => 'example.com',
           'User-Agent' => 'Ruby'
          }
        )
        .to_return(
          status: 200,
          body: { access_token: 'abc123' }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      stub_request(:get, "https://apim.crowncommercial.gov.uk/website-data/manual/paths/invoke/%5Batt%5D.%5Bvw_RMIActiveURNList%5D/?api-version=2016-10-01&filter=Published%20eq%20'True'&sp=/triggers/manual/run&sv=1.0")
        .with(
          headers: {
            'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer abc123',
          'User-Agent' => 'Ruby'
          }
        )
        .to_return(
          status: 200,
          body: [
            {
              urn: 10009655,
              name: 'Government Commercial Agency',
              postcode: 'L3 9PP',
              sector: 'central_government',
              published: true
            }
          ].to_json,
          headers: { 'Content-Type' => 'application/json' }
        )

      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('MDM_API_TOKEN_URL').and_return('https://example.com/oauth/token')
      allow(ENV).to receive(:fetch).with('MDM_API_CLIENT_ID').and_return('test_client_id')
      allow(ENV).to receive(:fetch).with('MDM_API_CLIENT_SECRET').and_return('test_client_secret')
      allow(ENV).to receive(:fetch).with('MDM_API_SCOPE').and_return('test_scope')
    end

    it 'fetches and returns customer data' do
      client = described_class.new
      customers = client.fetch_customers

      expect(customers.size).to eq(1)
      expect(customers.first['urn']).to eq(10009655)
      expect(customers.first['name']).to eq('Government Commercial Agency')
      expect(customers.first['postcode']).to eq('L3 9PP')
      expect(customers.first['sector']).to eq('central_government')
      expect(customers.first['published']).to eq(true)
    end
  end
end
