class DashboardController < ActionController::Base
  layout 'application'
  def index
    @audio_generations = AudioGeneration.recent.limit(20)
  end
end
