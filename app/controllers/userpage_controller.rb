class UserpageController < ApplicationController
  layout 'application'
  before_action :authenticate_account!

  def login
    @account = current_account
    @msg = 'account created at: ' + @account.created_at.to_s
  end

  def form
  end

  def myanalysis
  end

  def totalanalysis
  end
end
