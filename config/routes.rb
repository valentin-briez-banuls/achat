Rails.application.routes.draw do
  devise_for :users

  # Household
  resource :household, only: [:new, :create, :show, :edit, :update]
  get "join/:token", to: "households#join", as: :join_household

  # Financial profile (singleton per household)
  resource :financial_profile, only: [:show, :new, :create, :edit, :update]

  # Property criteria (singleton per household)
  resource :property_criterion, only: [:show, :new, :create, :edit, :update]

  # Properties
  resources :properties do
    resources :simulations
    resources :visits, except: [:index, :show]
    resources :offers, except: [:index, :show]
  end

  # Comparator
  resource :comparison, only: [:show]

  # Dashboard
  get "dashboard", to: "dashboard#show", as: :dashboard

  # Root
  authenticated :user do
    root to: "dashboard#show", as: :authenticated_root
  end

  root to: redirect("/users/sign_in")

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
