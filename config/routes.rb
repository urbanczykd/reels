Rails.application.routes.draw do
  devise_for :users,
    controllers: { omniauth_callbacks: "omniauth_callbacks" }

  root "dashboard#index"

  resources :clips do
    member do
      post :generate
      post :upload_to_social
      get  :stream_video
    end
  end

  resources :social_accounts, only: [:index, :destroy]

  get "up" => "rails/health#show", as: :rails_health_check
end
