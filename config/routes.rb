Rails.application.routes.draw do
  devise_for :users, only: :sessions, path: "", path_names: { sign_in: "login", sign_out: "logout" },
    controllers: { sessions: "users/sessions" }
  resource :company_selection, only: %i[ new create ]
  resource :password, only: %i[ edit update ]

  resource :settings, only: :show
  resource :company, only: :update
  resources :people, only: %i[ new create ] do
    member do
      patch :disable
      patch :enable
      patch :unlock
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
