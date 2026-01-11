Rails.application.routes.draw do
  # API routes
  root 'dashboard#index'
  
  namespace :api do
    namespace :v1 do
      post 'generate_voice', to: 'audio_generations#generate_voice'
      resources :audio_generations, only: [:index, :show]
    end
  end
  
  # Defines the root path route ("/")
  # root "articles#index"
end
