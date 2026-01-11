require 'rails_helper'

RSpec.describe Api::V1::AudioGenerationsController, type: :request do
  describe 'POST /api/v1/generate_voice' do
    let(:valid_params) do
      {
        audio_generation: {
          text: 'This is a test audio generation',
          voice_id: '21m00Tcm4TlvDq8ikWAM'
        }
      }
    end
    
    context 'with valid parameters' do
      it 'creates a new audio generation' do
        expect {
          post '/api/v1/generate_voice', params: valid_params, as: :json
        }.to change(AudioGeneration, :count).by(1)
      end
      
      it 'returns created status' do
        post '/api/v1/generate_voice', params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end
      
      it 'returns generation details' do
        post '/api/v1/generate_voice', params: valid_params, as: :json
        json = JSON.parse(response.body)
        expect(json['id']).to be_present
        expect(json['status']).to eq('pending')
        expect(json['text']).to eq('This is a test audio generation')
      end
      
      it 'enqueues background job' do
        expect {
          post '/api/v1/generate_voice', params: valid_params, as: :json
        }.to have_enqueued_job(GenerateAudioJob)
      end
    end
    
    context 'with invalid parameters' do
      it 'returns unprocessable_entity for empty text' do
        post '/api/v1/generate_voice', params: { audio_generation: { text: '' } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
      
      it 'returns error messages' do
        post '/api/v1/generate_voice', params: { audio_generation: { text: '' } }, as: :json
        json = JSON.parse(response.body)
        expect(json['errors']).to be_present
      end
    end
  end
  
  describe 'GET /api/v1/audio_generations' do
    let!(:generations) { create_list(:audio_generation, 3, :completed) }
    
    it 'returns list of audio generations' do
      get '/api/v1/audio_generations', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['audio_generations'].length).to eq(3)
    end
    
    it 'filters by status' do
      create(:audio_generation, :failed)
      get '/api/v1/audio_generations', params: { status: 'completed' }, headers: { 'Accept' => 'application/json' }
      json = JSON.parse(response.body)
      expect(json['audio_generations'].all? { |g| g['status'] == 'completed' }).to be true
    end
    
    it 'supports pagination' do
      get '/api/v1/audio_generations', params: { page: 1, per_page: 2 }, headers: { 'Accept' => 'application/json' }
      json = JSON.parse(response.body)
      expect(json['audio_generations'].length).to eq(2)
      expect(json['page']).to eq(1)
      expect(json['per_page']).to eq(2)
    end
  end
  
  describe 'GET /api/v1/audio_generations/:id' do
    let(:generation) { create(:audio_generation, :completed) }
    
    it 'returns audio generation details' do
      get "/api/v1/audio_generations/#{generation.id}", headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['id']).to eq(generation.id)
      expect(json['audio_url']).to eq(generation.audio_url)
    end
    
    it 'returns not_found for invalid id' do
      get '/api/v1/audio_generations/99999', headers: { 'Accept' => 'application/json' }
      expect(response).to have_http_status(:not_found)
    end
  end
end
