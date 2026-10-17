Rails.application.routes.draw do
  resource :session, only: %i[ new create destroy ]
  resource :company_selection, only: %i[ new create ]
  resource :password, only: %i[ edit update ]

  resource :settings, only: :show
  resource :company, only: :update
  resources :people, only: %i[ new create ] do
    member do
      patch :disable
      patch :enable
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
