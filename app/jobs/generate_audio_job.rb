class GenerateAudioJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: :exponentially_longer, attempts: 3
  
  def perform(audio_generation_id)
    audio_generation = AudioGeneration.find(audio_generation_id)
    
    Rails.logger.info "Starting audio generation job for ID: #{audio_generation_id}"
    
    # Update status to processing
    audio_generation.update!(status: 'processing')
    
    # Generate audio using ElevenLabs
    eleven_labs = ElevenLabsService.new
    audio_data = eleven_labs.generate_speech(
      audio_generation.text,
      audio_generation.voice_id
    )
    
    # Upload to Cloudinary
    cloudinary = CloudinaryService.new
    filename = "audio_#{audio_generation.id}_#{Time.current.to_i}"
    upload_result = cloudinary.upload_audio(audio_data, filename)
    
    # Update record with results
    audio_generation.update!(
      status: 'completed',
      audio_url: upload_result[:url],
      cloudinary_public_id: upload_result[:public_id],
      duration: upload_result[:duration],
      file_size: upload_result[:bytes]
    )
    
    Rails.logger.info "Successfully completed audio generation for ID: #{audio_generation_id}"
    
  rescue StandardError => e
    Rails.logger.error "Audio generation failed for ID #{audio_generation_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    
    audio_generation.update!(
      status: 'failed',
      error_message: "#{e.class}: #{e.message}"
    )
    
    raise # Re-raise to trigger retry logic
  end
end
