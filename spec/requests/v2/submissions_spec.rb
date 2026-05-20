require 'rails_helper'

RSpec.describe 'V2::Submissions', type: :request do
  let(:valid_api_key) { create(:api_key) }
  let(:invalid_api_key) { 'invalid_key' }

  describe 'GET /v2/submissions' do
    context 'with valid API key' do
      before do
        create_list(:submission, 3)
        get v2_submissions_path, headers: { 'API-Key' => valid_api_key.key }
      end

      it 'returns all submissions when updated_at is not provided' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(3)
      end

      it 'returns submissions updated since the provided date' do
        old_submission = create(:submission, updated_at: 3.days.ago)
        recent_submission = create(:submission, updated_at: 1.hour.ago)

        get v2_submissions_path, params: { updated_at: 2.days.ago.iso8601 }, headers: { 'API-Key' => valid_api_key.key }
        submission_ids = JSON.parse(response.body).pluck('id')

        expect(response).to have_http_status(:ok)
        expect(submission_ids).to include(recent_submission.id)
        expect(submission_ids).not_to include(old_submission.id)
      end
    end

    context 'with missing API key' do
      before { get v2_submissions_path }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('API key is missing')
      end
    end

    context 'with invalid API key' do
      before { get v2_submissions_path, headers: { 'API-Key' => invalid_api_key } }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('API key is invalid')
      end
    end
  end
end
