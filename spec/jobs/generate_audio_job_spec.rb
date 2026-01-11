require 'rails_helper'

RSpec.describe GenerateAudioJob, type: :job do
  let(:audio_generation) { create(:audio_generation) }
  let(:audio_data) { 'binary_audio_data' }
  let(:upload_result) do
    {
      url: 'https://res.cloudinary.com/test/audio.mp3',
      public_id: 'voice_generations/audio_1',
      duration: 5.2,
      bytes: 82400
    }
  end
  
  before do
    ENV['ELEVENLABS_API_KEY'] = 'test_api_key'
    ENV['CLOUDINARY_CLOUD_NAME'] = 'test_cloud'
    ENV['CLOUDINARY_API_KEY'] = 'test_key'
    ENV['CLOUDINARY_API_SECRET'] = 'test_secret'
  end
  
  describe '#perform' do
    context 'when generation is successful' do
      before do
        allow_any_instance_of(ElevenLabsService).to receive(:generate_speech)
          .and_return(audio_data)
        allow_any_instance_of(CloudinaryService).to receive(:upload_audio)
          .and_return(upload_result)
      end
      
      it 'updates status to processing' do
        described_class.new.perform(audio_generation.id)
        audio_generation.reload
        # Status will be 'completed' after job finishes
        expect(['processing', 'completed']).to include(audio_generation.status)
      end
      
      it 'calls ElevenLabsService' do
        expect_any_instance_of(ElevenLabsService).to receive(:generate_speech)
          .with(audio_generation.text, audio_generation.voice_id)
        described_class.new.perform(audio_generation.id)
      end
      
      it 'calls CloudinaryService' do
        expect_any_instance_of(CloudinaryService).to receive(:upload_audio)
          .with(audio_data, anything)
        described_class.new.perform(audio_generation.id)
      end
      
      it 'updates audio generation with results' do
        described_class.new.perform(audio_generation.id)
        audio_generation.reload
        expect(audio_generation.status).to eq('completed')
        expect(audio_generation.audio_url).to eq(upload_result[:url])
        expect(audio_generation.cloudinary_public_id).to eq(upload_result[:public_id])
        expect(audio_generation.duration).to eq(upload_result[:duration])
        expect(audio_generation.file_size).to eq(upload_result[:bytes])
      end
    end
    
    context 'when generation fails' do
      before do
        allow_any_instance_of(ElevenLabsService).to receive(:generate_speech)
          .and_raise(ElevenLabsService::APIError, 'API Error')
      end
      
      it 'updates status to failed' do
        expect {
          described_class.new.perform(audio_generation.id)
        }.to raise_error(ElevenLabsService::APIError)
        
        audio_generation.reload
        expect(audio_generation.status).to eq('failed')
        expect(audio_generation.error_message).to include('API Error')
      end
    end
  end
end
