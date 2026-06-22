require 'rails_helper'

RSpec.describe 'V2::Tasks', type: :request do
  let(:valid_api_key) { create(:api_key) }
  let(:invalid_api_key) { 'invalid_key' }

  describe 'GET /v2/tasks' do
    context 'with valid API key' do
      before do
        create_list(:task, 3)
        get v2_tasks_path, headers: { 'API-Key' => valid_api_key.key }
      end

      it 'returns all tasks when updated_at is not provided' do
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).size).to eq(3)
      end

      it 'returns tasks updated since the provided date' do
        old_task = create(:task, updated_at: 3.days.ago)
        recent_task = create(:task, updated_at: 1.hour.ago)

        get v2_tasks_path, params: { updated_at: 2.days.ago.iso8601 }, headers: { 'API-Key' => valid_api_key.key }
        task_ids = JSON.parse(response.body).pluck('id')

        expect(response).to have_http_status(:ok)
        expect(task_ids).to include(recent_task.id)
        expect(task_ids).not_to include(old_task.id)
      end
    end

    context 'with missing API key' do
      before { get v2_tasks_path }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('API key is missing')
      end
    end

    context 'with invalid API key' do
      before { get v2_tasks_path, headers: { 'API-Key' => invalid_api_key } }

      it 'returns unauthorized status' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)['error']).to eq('API key is invalid')
      end
    end
  end
end
