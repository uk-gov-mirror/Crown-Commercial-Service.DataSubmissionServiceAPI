require 'rails_helper'

RSpec.describe UserLogsInAuth0 do
  describe '#call' do
    let(:user) { create(:user) }

    subject { described_class.new(user: user).call }

    before(:each) do
      stub_auth0_token_request
    end

    it 'fetches logs from Auth0' do
      expected_query = "(type:\"s\" OR type:\"f\") AND user_id:\"#{user.auth_id}\""
      auth0_logs_call = stub_request(:get, 'https://testdomain/api/v2/logs')
                        .with(query: hash_including('q' => expected_query))
                        .to_return(status: 200, body: '[]', headers: { 'Content-Type' => 'application/json' })

      subject

      expect(auth0_logs_call).to have_been_requested
    end
  end
end
