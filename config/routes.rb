Rails.application.routes.draw do
  root to: 'index#introduction'
  get 'form', to:'maches#index'
  get 'mychart', to:'maches#index'
  get 'totalchart', to:'maches#index'

  get 'links/index', to:'maches#index'
  get 'master/index', to:'master#index'

  get 'links/:kc/form', to:'maches#form'
  post 'links/:kc/form', to:'maches#create'
  get 'links/:kc/sended_form', to:'maches#sended_form'
  get 'links/:kc/mychart', to:'maches#mychart'
  get 'links/:kc/mychart/my_duel_data.csv', to:'maches#mydata_csv'
  get 'links/:kc/totalchart', to:'maches#totalchart'
  get 'links/:kc/edit/:id', to: 'maches#edit'
  patch 'links/:kc/edit/:id', to: 'maches#update'
  get 'links/:kc/delete/:id', to:'maches#delete'
  get 'links/:kc/:deck', to:'maches#deckchart'

  get 'master/:dc/form', to:'master#form'
  post 'master/:dc/form', to:'master#create'
  get 'master/:dc/sended_form', to:'master#sended_form'
  get 'master/:dc/mychart', to:'master#mychart'
  get 'master/:dc/mychart/my_duel_data.csv', to:'master#mydata_csv'
  get 'master/:dc/totalchart', to:'master#totalchart'
  get 'master/:dc/edit/:id', to: 'master#edit'
  patch 'master/:dc/edit/:id', to: 'master#update'
  get 'master/:dc/delete/:id', to:'master#delete'
  get 'master/:dc/close', to:'master#close'
  
  get 'admin/export', to:'admin#export'
  get 'admin/export/accounts.csv', to:'admin#export_accounts'
  get 'admin/export/matches.csv', to:'admin#export_matches'
  get 'admin/user_list', to:'admin#user_list'
  get 'admin/inquiry_list', to:'admin#inquiry_list'
  get 'admin/inquiry/delete/:id', to:'admin#inquiry_delete'

  post 'select_kc', to:'maches#select_kc'
  post 'select_datetime', to:'maches#select_datetime'
  post 'select_dprange', to:'maches#select_dprange'

  get 'past_kc', to:'index#past_kc'
  get 'past_kc/:kcname', to:'index#past_kc_chart'
  
  devise_for :accounts

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
