Rails.application.routes.draw do
  root 'maches#index'
  get 'form', to:'maches#form'
  post 'form', to:'maches#create'
  get 'sended_form', to:'maches#sended_form'
  get 'mychart', to:'maches#mychart'
  get 'totalchart', to:'maches#totalchart'
  get 'edit/:id', to: 'maches#edit'
  patch 'edit/:id', to: 'maches#update'
  get 'delete', to:'maches#delete'
  post 'delete', to:'maches#delete'
  devise_for :accounts
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
