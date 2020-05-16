class TopController < ApplicationController
  layout 'application'
  before_action :authenticate_account!, only: :login

  def index
    @msg = 'this is sample page.'
  end

  def login
    @account = current_account
    @msg = 'account created at: ' + @account.created_at.to_s
  end
end
