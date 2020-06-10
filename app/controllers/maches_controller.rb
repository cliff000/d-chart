class MachesController < ApplicationController
  layout 'application'
  before_action :authenticate_account!

  def index
    @account = current_account
    @msg = 'account created at: ' + @account.created_at.to_s
    @lastData = Match.last
  end

  def form
    @match = Match.new
    @data = Match.all
    @lastData = Match.where(playerid: current_account.id).last
  end

  def sended_form
  end

  def create
    if request.post? then
      tmp = Match.new(match_params)
      tmp.playerid = current_account.id

      dp = 0
      if Match.where(playerid: current_account.id).exists? then
        dp = Match.where(playerid: current_account.id).last.dp
      end
      if tmp.victory == "勝ち" then
        dp += 1000
      else 
        dp -= 1000
        if dp < 0 then
          dp = 0
        end
      end
      tmp.dp = dp

      tmp.tag = "KCGT"

      tmp.save
    end
    redirect_to action: :sended_form
  end

  def mychart
    @account = current_account
    @data = Match.where(playerid: current_account.id)
  end

  def totalchart
    @data = Match.all
    @recentData = Match.where(created_at: (Time.now - 7200)..Float::INFINITY).group(:oppdeck)
  end

  def delete
    @account = current_account
    @match = Match.new

    if request.post? then
      Match.all.destroy_all
      redirect_to action: :index
    end
  end

  private
  def match_params
    params.require(:match).permit(:playerid, :mydeck, :myskill, :oppdeck, :oppskill, :victory, :dp)
  end
end
