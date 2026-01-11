class CloudinaryService
  class UploadError < StandardError; end
  
  def initialize
    configure_cloudinary
  end
  
  # Upload audio file to Cloudinary
  # @param file_data [String] Binary audio data
  # @param filename [String] Desired filename (without extension)
  # @return [Hash] Upload result with :url and :public_id
  def upload_audio(file_data, filename)
    Rails.logger.info "Uploading audio to Cloudinary: #{filename}"
    
    # Create a temporary file
    temp_file = create_temp_file(file_data, filename)
    
    begin
      result = Cloudinary::Uploader.upload(
        temp_file.path,
        resource_type: 'video', # Cloudinary uses 'video' for audio files
        public_id: filename,
        folder: 'voice_generations',
        format: 'mp3',
        overwrite: false,
        unique_filename: true
      )
      
      Rails.logger.info "Successfully uploaded to Cloudinary: #{result['secure_url']}"
      
      {
        url: result['secure_url'],
        public_id: result['public_id'],
        duration: result['duration'],
        bytes: result['bytes']
      }
    rescue CloudinaryException => e
      Rails.logger.error "Cloudinary upload failed: #{e.message}"
      raise UploadError, "Failed to upload to Cloudinary: #{e.message}"
    ensure
      temp_file.close
      temp_file.unlink
    end
  end
  
  # Delete audio file from Cloudinary
  # @param public_id [String] The Cloudinary public ID
  def delete_audio(public_id)
    return if public_id.blank?
    
    Rails.logger.info "Deleting audio from Cloudinary: #{public_id}"
    Cloudinary::Uploader.destroy(public_id, resource_type: 'video')
  rescue CloudinaryException => e
    Rails.logger.error "Cloudinary deletion failed: #{e.message}"
    # Don't raise error on deletion failure
  end
  
  private
  
  def configure_cloudinary
    Cloudinary.config do |config|
      config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
      config.api_key = ENV['CLOUDINARY_API_KEY']
      config.api_secret = ENV['CLOUDINARY_API_SECRET']
      config.secure = true
    end
    
    validate_configuration
  end
  
  def validate_configuration
    missing = []
    missing << 'CLOUDINARY_CLOUD_NAME' if ENV['CLOUDINARY_CLOUD_NAME'].blank?
    missing << 'CLOUDINARY_API_KEY' if ENV['CLOUDINARY_API_KEY'].blank?
    missing << 'CLOUDINARY_API_SECRET' if ENV['CLOUDINARY_API_SECRET'].blank?
    
    if missing.any?
      raise ArgumentError, "Missing Cloudinary configuration: #{missing.join(', ')}"
    end
  end
  
  def create_temp_file(file_data, filename)
    temp_file = Tempfile.new([filename, '.mp3'])
    temp_file.binmode
    temp_file.write(file_data)
    temp_file.rewind
    temp_file
  end
end
