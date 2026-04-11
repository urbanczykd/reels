Rails.application.routes.draw do
  devise_for :users,
    controllers: { omniauth_callbacks: "omniauth_callbacks" }

  # Admin
  require "sidekiq/web"
  authenticate :user, ->(u) { u.admin? } do
    mount Sidekiq::Web => "/admin/sidekiq"
  end

  get   "/admin",                      to: "admin#dashboard",       as: :admin_dashboard
  post   "/admin/clips/:id/stop",      to: "admin#stop_clip",       as: :admin_stop_clip
  post   "/admin/clips/:id/retry",     to: "admin#retry_clip",      as: :admin_retry_clip
  delete "/admin/clips/:id",           to: "admin#destroy_clip",    as: :admin_destroy_clip

  root "dashboard#index"

  resources :clips do
    member do
      post :generate
      post :upload_to_social
      get  :stream_video
      get  :progress
    end
  end

  resources :social_accounts, only: [:index, :destroy]
  resources :soundtracks, only: [:index, :new, :create, :destroy]

  get "up" => "rails/health#show", as: :rails_health_check
end
