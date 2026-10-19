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

  resources :activity_logs, path: "activity", only: :index

  get "purchases", to: redirect("/purchases/orders")
  scope "purchases" do
    resources :purchase_orders, path: "orders" do
      member do
        post :submit
        post :approve
        post :receive
        post :pay
        post :cancel
        get :copy
      end
    end
    resources :suppliers, except: %i[ show destroy ]
  end

  resources :customers, except: :destroy
  resources :sales_orders, path: "orders", only: %i[ index show new create ] do
    member do
      post :dispatch_goods, path: "dispatch"
      post :deliver
      post :cancel
    end
  end
  resources :payments, only: %i[ index show new create ] do
    post :reverse, on: :member
  end
  resource :khata, only: :show, controller: "khata"
  resources :invoices, path: "bills", only: %i[ index show ] do
    member do
      post :extend_due
      post :cancel
    end
  end

  get "stock", to: redirect("/stock/items")
  scope "stock" do
    resources :items, except: :destroy
    resources :stock_moves, path: "moves", only: :index
    resources :units, except: :show
    resources :production_issues, path: "issues", only: %i[ new create ]
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#show"
end
