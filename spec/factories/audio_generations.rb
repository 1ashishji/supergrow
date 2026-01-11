FactoryBot.define do
  factory :audio_generation do
    text { "This is a test audio generation." }
    status { "pending" }
    voice_id { "21m00Tcm4TlvDq8ikWAM" }
    
    trait :processing do
      status { "processing" }
    end
    
    trait :completed do
      status { "completed" }
      audio_url { "https://res.cloudinary.com/test/video/upload/voice_generations/audio_1.mp3" }
      cloudinary_public_id { "voice_generations/audio_1" }
      duration { 5.2 }
      file_size { 82400 }
    end
    
    trait :failed do
      status { "failed" }
      error_message { "API Error: Rate limit exceeded" }
    end
  end
end
