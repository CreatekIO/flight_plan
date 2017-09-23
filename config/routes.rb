Rails.application.routes.draw do
  root to: 'boards#index'

  resources :boards
  resources :tickets
end
