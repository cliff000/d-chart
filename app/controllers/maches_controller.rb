require 'csv'
require "json"

class MachesController < ApplicationController
  layout 'maches'
  before_action :authenticate_account!

  #現在のKC
  $kc = 'Free'

  def index
    @account = current_account
    @msg = 'account created at: ' + @account.created_at.to_s
    @lastData = Match.last
  end

  def form
    @match = Match.new
    @lastData = Match.where(tag: $kc).where(playerid: current_account.id).last
    @decks = CSV.read("#{Rails.root}/config_duellinks/"+$kc+"/decks.csv")
    @skills = CSV.read("#{Rails.root}/config_duellinks/"+$kc+"/skills.csv")

    #スキルリスト読み込み
    File.open("#{Rails.root}/config_duellinks/"+$kc+"/major_skill.json") do |file|
      gon.major_skill = JSON.load(file)
    end
  end

  def sended_form
    @lastData = Match.where(playerid: current_account.id).last
  end

  def create
    if request.post? then
      tmp = Match.new(match_params)
      tmp.playerid = current_account.id

      dp = 0
      if Match.where(tag: $kc).where(playerid: current_account.id).exists? then
        dp = Match.where(tag: $kc).where(playerid: current_account.id).last.dp
      end
      if tmp.victory == "勝ち" then
        dp += tmp.dpChanging
      else 
        dp -= tmp.dpChanging
        if dp < 0 then
          dp = 0
        end
      end
      tmp.dp = dp

      tmp.tag = $kc

      tmp.save
    end
    redirect_to action: :sended_form
  end

  def test
  end

  def mychart
    @account = current_account
    @data = Match.where(tag: $kc).where(playerid: current_account.id)
    oppdecks = @data.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}

    #デッキ分布のデータ作成
    others_val = 0
    oppdecks2 = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "その他") && (i < 9) then
        oppdecks2.push({"category" => key, "column-1" => value})
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      oppdecks2.push({"category" => "その他", "column-1" => others_val})
    end
    gon.oppdecks_mychart = oppdecks2

    #DP推移のデータ作成
    dpline = Array.new()
    i = 0
    for obj in @data do
      i += 1
      dpline.push({"category" => i, "column-1" => obj.dp})
    end
    gon.dpline_mychart = dpline

    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  def mydata_csv
    @data = Match.where(tag: $kc).where(playerid: current_account.id)
  end

  def totalchart
    @data = Match.where(tag: $kc)
    oppdecks = @data.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}

    #デッキ分布のデータ作成
    others_val = 0
    oppdecks2 = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "その他") && (i < 9) then
        oppdecks2.push({"category" => key, "column-1" => value})
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      oppdecks2.push({"category" => "その他", "column-1" => others_val})
    end
    gon.oppdecks_totalchart = oppdecks2

    #直近のデッキ分布のデータ作成
    @recentData = @data.where(created_at: (Time.now - 7200)..Float::INFINITY)
    oppdecks = @recentData.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}
    others_val = 0
    oppdecks2 = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "その他") && (i < 9) then
        oppdecks2.push({"category" => key, "column-1" => value})
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      oppdecks2.push({"category" => "その他", "column-1" => others_val})
    end
    gon.recent_oppdecks_totalchart = oppdecks2

    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  def select_kc
    $kc = params[:kc]
  end

  def edit
    @account = current_account
    @selectedData = Match.find(params[:id])
    @decks = CSV.read("#{Rails.root}/config_duellinks/"+$kc+"/decks.csv")
    @skills = CSV.read("#{Rails.root}/config_duellinks/"+$kc+"/skills.csv")
  end

  def update
    obj = Match.find(params[:id])
    obj.update(match_params)
    dpUpdate()
    redirect_to action: :mychart
  end

  def all_delete
    @account = current_account
    @match = Match.new

    if request.post? then
      Match.all.destroy_all
      redirect_to action: :index
    end
  end

  def delete
    obj = Match.find(params[:id])
    if obj.playerid == current_account.id then
      obj.destroy
      dpUpdate()
    end
    redirect_to action: :mychart
  end

  private
  def match_params
    params.require(:match).permit(:mydeck, :myskill, :oppdeck, :oppskill, :victory, :dpChanging)
  end

  def dpUpdate
    data = Match.where(tag: $kc).where(playerid: current_account.id)
    preDP = 0
    for obj in data do
      if obj.victory == "勝ち" then
        obj.dp = preDP + obj.dpChanging
      else 
        obj.dp = preDP - obj.dpChanging
        if obj.dp < 0 then
          obj.dp = 0
        end
      end
      preDP = obj.dp
      obj.save
    end
  end
end
