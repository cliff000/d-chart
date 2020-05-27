Rails.application.routes.draw do
  root 'maches#index'
  get 'form', to:'maches#form'
  post 'form', to:'maches#create'
  get 'sended_form', to:'maches#sended_form'
  get 'me', to:'maches#me'
  get 'total', to:'maches#total'
  devise_for :accounts
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
