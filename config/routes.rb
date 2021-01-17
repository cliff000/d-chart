Rails.application.routes.draw do
  root 'maches#mychart'
  get 'form', to:'maches#form'
  post 'form', to:'maches#create'
  get 'sended_form', to:'maches#sended_form'
  get 'mychart', to:'maches#mychart'
  get 'mychart/my_duel_data.csv', to:'maches#mydata_csv'
  get 'totalchart', to:'maches#totalchart'
  get 'trahclatot', to:'maches#totalchart'
  get 'trahclatot/:start/:end', to:'maches#totalchart'
  get 'edit/:id', to: 'maches#edit'
  patch 'edit/:id', to: 'maches#update'
  get 'delete/:id', to:'maches#delete'
  get 'chart/:deck', to:'maches#deckchart'

  get 'privacy_policy', to:'inquiry#privacy_policy'
  get 'inquiry', to:'inquiry#form'
  post 'inquiry', to:'inquiry#create'

  get 'admin/export', to:'admin#export'
  get 'admin/export/accounts.csv', to:'admin#export_accounts'
  get 'admin/export/matches.csv', to:'admin#export_matches'
  get 'admin/user_list', to:'admin#user_list'
  get 'admin/inquiry_list', to:'admin#inquiry_list'
  get 'admin/inquiry/delete/:id', to:'admin#inquiry_delete'

  post 'select_kc', to:'maches#select_kc'
  post 'select_datetime', to:'maches#select_datetime'
  post 'select_dprange', to:'maches#select_dprange'
  get 'create_kc', to:'maches#create_kc'

  get 'test', to:'maches#test'
  
  devise_for :accounts

  Rails.application.routes.draw do
    root 'chart#index'
  end

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
