class ElevenLabsService
  include HTTParty
  base_uri 'https://api.elevenlabs.io/v1'
  
  class APIError < StandardError; end
  
  def initialize
    @api_key = ENV['ELEVENLABS_API_KEY']
    raise ArgumentError, 'ELEVENLABS_API_KEY not set' if @api_key.blank?
  end
  
  # Generate speech from text using ElevenLabs API
  # @param text [String] The text to convert to speech
  # @param voice_id [String] The voice ID to use (default: Rachel)
  # @return [String] Binary audio data (MP3 format)
  def generate_speech(text, voice_id = '21m00Tcm4TlvDq8ikWAM')
    Rails.logger.info "Generating speech with ElevenLabs for voice_id: #{voice_id}"
    
    response = self.class.post(
      "/text-to-speech/#{voice_id}",
      headers: headers,
      body: request_body(text).to_json,
      timeout: 30
    )
    
    if response.success?
      Rails.logger.info "Successfully generated speech (#{response.body.bytesize} bytes)"
      response.body
    else
      error_message = parse_error(response)
      Rails.logger.error "ElevenLabs API error: #{error_message}"
      raise APIError, error_message
    end
  rescue HTTParty::Error, Timeout::Error => e
    Rails.logger.error "ElevenLabs request failed: #{e.message}"
    raise APIError, "Failed to connect to ElevenLabs: #{e.message}"
  end
  
  private
  
  def headers
    {
      'xi-api-key' => @api_key,
      'Content-Type' => 'application/json',
      'Accept' => 'audio/mpeg'
    }
  end
  
  def request_body(text)
    {
      text: text,
      model_id: 'eleven_turbo_v2_5', # Updated to free tier compatible model
      voice_settings: {
        stability: 0.5,
        similarity_boost: 0.75
      }
    }
  end
  
  def parse_error(response)
    return "HTTP #{response.code}: #{response.message}" unless response.body
    
    begin
      error_data = JSON.parse(response.body)
      error_data['detail'] || error_data['message'] || response.message
    rescue JSON::ParserError
      response.message
    end
  end
end
