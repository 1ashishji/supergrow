require 'rails_helper'

RSpec.describe ElevenLabsService do
  let(:service) { described_class.new }
  let(:voice_id) { '21m00Tcm4TlvDq8ikWAM' }
  let(:text) { 'Hello, this is a test.' }
  
  before do
    ENV['ELEVENLABS_API_KEY'] = 'test_api_key'
  end
  
  describe '#initialize' do
    it 'raises error if API key is not set' do
      ENV['ELEVENLABS_API_KEY'] = nil
      expect { described_class.new }.to raise_error(ArgumentError, /ELEVENLABS_API_KEY/)
    end
  end
  
  describe '#generate_speech' do
    let(:api_url) { "https://api.elevenlabs.io/v1/text-to-speech/#{voice_id}" }
    let(:audio_data) { 'binary_audio_data' }
    
    context 'when API call is successful' do
      before do
        stub_request(:post, api_url)
          .with(
            headers: {
              'xi-api-key' => 'test_api_key',
              'Content-Type' => 'application/json',
              'Accept' => 'audio/mpeg'
            }
          )
          .to_return(status: 200, body: audio_data)
      end
      
      it 'returns audio data' do
        result = service.generate_speech(text, voice_id)
        expect(result).to eq(audio_data)
      end
    end
    
    context 'when API call fails' do
      before do
        stub_request(:post, api_url)
          .to_return(status: 429, body: { detail: 'Rate limit exceeded' }.to_json)
      end
      
      it 'raises APIError' do
        expect {
          service.generate_speech(text, voice_id)
        }.to raise_error(ElevenLabsService::APIError, /Rate limit exceeded/)
      end
    end
    
    context 'when network error occurs' do
      before do
        stub_request(:post, api_url).to_timeout
      end
      
      it 'raises APIError' do
        expect {
          service.generate_speech(text, voice_id)
        }.to raise_error(ElevenLabsService::APIError, /Failed to connect/)
      end
    end
  end
end
