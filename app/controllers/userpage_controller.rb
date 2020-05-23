class UserpageController < ApplicationController
  layout 'application'
  before_action :authenticate_account!

  def login
    @account = current_account
    @msg = 'account created at: ' + @account.created_at.to_s
  end

  def form
    @match = Match.new
  end

  def create
    if request.post? then
      tmp = Match.new(match_params)
      tmp.playerid = current_account.id
      tmp.save
    end
    redirect_to '/userpage/login'
  end

  def myanalysis
    @data = Match.where(playerid: current_account.id)
  end

  def totalanalysis
    @data = Match.all
  end

  private
  def match_params
    params.require(:match).permit(:playerid, :mydeck, :myskill, :oppdeck, :oppskill, :victory, :dp)
  end
end
