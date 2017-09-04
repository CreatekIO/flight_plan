Rails.application.routes.draw do
  root to: 'boards#show'

  resources :tickets
end
