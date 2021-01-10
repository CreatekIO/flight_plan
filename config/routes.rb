Rails.application.routes.draw do
  authenticated :user do
    root to: 'boards#index', as: :authenticated_root
  end

  root to: 'pages#index'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resources :features, param: :name, only: %i[update destroy]

  resources :boards do
    resources :board_tickets, as: :tickets, only: %i[show create] do
      resources :moves, controller: :ticket_moves, only: :create
    end
    get 'tickets/:slug/:number' => 'board_tickets#show', as: :slugged_ticket, constraints: {
      slug: %r{[a-z0-9\-]+/[a-z0-9\-_]+}i
    }
    get 'pull_requests' => 'pull_request_dashboards#index', as: :pull_requests
    resources :next_actions, only: :index

    resources :kpis, only: :index

    # This needs to be last to avoid it intercepting the routes above
    get '*extras' => :show, as: :client_side, on: :member, constraints: { format: :html }
  end

  resources :swimlanes, only: [] do
    resources :tickets, controller: :board_tickets, only: :index
  end

  namespace :webhook do
    resource :github, only: :create, defaults: { formats: :json }, controller: 'github'
  end

  namespace :api do
    resources :boards, only: :show do
      resources :board_tickets, only: %i[index]
      resources :releases, only: :create
    end
  end
end
