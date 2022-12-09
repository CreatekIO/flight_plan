Rails.application.routes.draw do
  authenticated :user do
    root to: 'boards#index', as: :authenticated_root
  end

  root to: 'pages#index'

  authenticate :user do
    mount Flipper::UI.app(Flipper), at: '/__flipper__'
  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  resource :user, only: [] do
    resources :features, param: :name, only: %i[destroy] do
      post :create, on: :member
    end
  end

  resources :boards do
    resources :board_tickets, as: :tickets, only: %i[show create] do
      resources :moves, controller: :ticket_moves, only: :create
      resource :labelling, path: 'labels', only: :update
      resource :assignment, path: 'assignees', controller: 'ticket_assignments', only: :update
    end
    get 'tickets/:slug/:number' => 'board_tickets#show', as: :slugged_ticket, constraints: {
      slug: %r{[a-z0-9\-]+/[a-z0-9\-_]+}i
    }
    resources :next_actions, only: :index

    resources :kpis, only: :index
    resource :cumulative_flow, only: :show, controller: 'cumulative_flow'

    # This needs to be last to avoid it intercepting the routes above
    get '*extras' => :show, as: :client_side, on: :member, constraints: { format: :html }
  end

  resources :swimlanes, only: [] do
    resources :tickets, controller: :board_tickets, only: :index
  end

  resources :repos, only: [] do
    resources :labels, only: :index
    resources :assignees, only: :index
  end

  namespace :webhook, only: :create, format: :json do
    resource :github, controller: 'github'
    resource :opsworks
  end

  namespace :api do
    resources :boards, only: :show do
      resources :board_tickets, only: %i[index]
      resources :releases, only: :create
    end
  end

  get '/__components__(/*extras)' => 'components#index', as: :components if Rails.env.development?
end
