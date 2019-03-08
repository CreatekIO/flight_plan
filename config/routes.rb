Rails.application.routes.draw do
  authenticated :user do
    root to: 'boards#index', as: :authenticated_root
  end

  root to: 'pages#index'

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }

  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :boards do
    resources :board_tickets
    get 'pull_requests' => 'pull_request_dashboards#index', as: :pull_requests
  end

  namespace :webhook do
    resource :github, only: :create, defaults: { formats: :json }, controller: 'github'
  end

  namespace :api do
    resources :boards, only: :show do
      resources :board_tickets, only: %i[index create]
      resources :releases, only: :create
    end
  end
end
