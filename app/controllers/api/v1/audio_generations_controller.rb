module Api
  module V1
    class AudioGenerationsController < ApplicationController
      before_action :set_audio_generation, only: [:show]
      
      # POST /api/v1/generate_voice
      def generate_voice
        audio_generation = AudioGeneration.new(audio_generation_params)
        
        if audio_generation.save
          # Enqueue background job
          GenerateAudioJob.perform_later(audio_generation.id)
          
          render json: {
            id: audio_generation.id,
            status: audio_generation.status,
            text: audio_generation.text,
            created_at: audio_generation.created_at
          }, status: :created
        else
          render json: {
            errors: audio_generation.errors.full_messages
          }, status: :unprocessable_entity
        end
      end
      
      # GET /api/v1/audio_generations
      def index
        audio_generations = AudioGeneration.recent
        
        # Filter by status if provided
        if params[:status].present?
          audio_generations = audio_generations.by_status(params[:status])
        end
        
        # Pagination
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 20
        per_page = [per_page, 100].min # Max 100 per page
        
        audio_generations = audio_generations.limit(per_page).offset((page - 1) * per_page)
        
        render json: {
          audio_generations: audio_generations.map { |ag| audio_generation_json(ag) },
          page: page,
          per_page: per_page
        }
      end
      
      # GET /api/v1/audio_generations/:id
      def show
        render json: audio_generation_json(@audio_generation)
      end
      
      private
      
      def set_audio_generation
        @audio_generation = AudioGeneration.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Audio generation not found' }, status: :not_found
      end
      
      def audio_generation_params
        params.require(:audio_generation).permit(:text, :voice_id)
      end
      
      def audio_generation_json(audio_generation)
        {
          id: audio_generation.id,
          text: audio_generation.text,
          status: audio_generation.status,
          audio_url: audio_generation.audio_url,
          voice_id: audio_generation.voice_id,
          duration: audio_generation.duration,
          file_size: audio_generation.file_size,
          error_message: audio_generation.error_message,
          created_at: audio_generation.created_at,
          updated_at: audio_generation.updated_at
        }
      end
    end
  end
end
