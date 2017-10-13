Rails.application.routes.draw do
  root to: 'boards#index'

  resources :boards do
    resources :board_tickets
  end

  namespace :webhook do
    resource :github, only: :create, defaults: { formats: :json }, controller: 'github'
  end

end
