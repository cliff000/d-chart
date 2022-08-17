require 'csv'
require "json"

class MasterController < ApplicationController
  layout 'master'
  before_action :authenticate_account!

  @TIMEMIN = "2000-01-01T00:00"
  @TIMEMAX = "2200-01-01T00:00"

  def index
  end

  def form
    @match = MasterMatch.new
    @lastData = MasterMatch.where(tag: params[:dc]).where(playerid: current_account.id).last
    @decks = CSV.read("#{Rails.root}/config_duellinks/master/"+params[:dc]+"/decks.csv")
    @decks.push(["自分で入力する"])

    #初期値の設定
    @defaultDeck = "自分で入力する"
    if @lastData.nil?
      @defaultDeck = ""
      gon.lastdp = 0
    else
      @decks.each do |obj|
        deckname = (obj[1] == nil) ? obj[0] : obj[1]
        if deckname == @lastData.mydeck
          @defaultDeck = @lastData.mydeck
          break
        end
      end
      gon.lastdp = @lastData.dp
    end

    #KC区間取得
    tmp_json = {}
    File.open("#{Rails.root}/config_duellinks/master/"+params[:dc]+"/datetime.json") do |file|
      tmp_json = JSON.load(file)
    end
    kcRange = [Time.parse(tmp_json["1日目"][0]), Time.parse(tmp_json["4日目"][1])]
    @inKC = true
    if Time.now < kcRange[0] || Time.now > kcRange[1]
      @inKC = false
    end
  end

  def sended_form
    @lastData = MasterMatch.where(playerid: current_account.id).last
  end

  def create
    if request.post? then
      tmp = MasterMatch.new(match_params)
      tmp.playerid = current_account.id

      dpChanging = 0
      if MasterMatch.where(tag: params[:dc]).where(playerid: current_account.id).exists? then
        dpChanging = tmp.dp - MasterMatch.where(tag: params[:dc]).where(playerid: current_account.id).last.dp
      else 
        dpChanging = tmp.dp
      end
      if dpChanging < 0
        dpChanging = dpChanging * -1
      end
      tmp.dpChanging = dpChanging
      tmp.tag = params[:dc]
      tmp.save
    end
    redirect_to action: :sended_form
  end

  # 対戦データの読み込み
  def getDuelData
    @data = MasterMatch.where(tag: params[:dc])

    # 先行後攻絞り込み
    @order = ""
    if(params[:order] != nil && params[:order] != "")
      @order = params[:order]
      @data = @data.where(order: @order)
    end

    #KC区間取得
    tmp_json = {}
    File.open("#{Rails.root}/config_duellinks/master/"+params[:dc]+"/datetime.json") do |file|
      tmp_json = JSON.load(file)
    end

    # 時間での絞り込み
    @TIMEMIN = (Time.parse(tmp_json["1日目"][0]) - 5*60*60).strftime("%Y-%m-%dT%H:%M")
    @TIMEMAX = (Time.parse(tmp_json["4日目"][1]) + 19*60*60 - 1).strftime("%Y-%m-%dT%H:%M")
    @timeMin = nil
    @timeMax = nil
    if(params[:timeMin] != nil && params[:timeMin] != "")
      @timeMin = params[:timeMin]
    end
    if(params[:timeMax] != nil && params[:timeMax] != "")
      @timeMax = params[:timeMax]
    end
    if(@timeMin != nil && @timeMax != nil)
      @data = @data.where(created_at: (Time.parse(@timeMin) - 9*60*60)..(Time.parse(@timeMax) - 9*60*60))
    end

    # DPでの絞り込み
    tmp_dpMin = 0
    tmp_dpMax = Float::INFINITY
    @dpMin = nil
    @dpMax = nil
    if(params[:dpMin] != nil && params[:dpMin] != "")
      @dpMin = params[:dpMin]
      tmp_dpMin = @dpMin
    end
    if(params[:dpMax] != nil && params[:dpMax] != "")
      @dpMax = params[:dpMax]
      tmp_dpMax = @dpMax
    end
    @data = @data.where(dp: tmp_dpMin..tmp_dpMax)
  end

  # 円グラフ作成のための関数
  def pieChartData(match)
    deckname = {}
    File.open("#{Rails.root}/config_duellinks/master/deckname_japanese.json") do |file|
      deckname = JSON.load(file)
    end
    others_val = 0
    oppdecks = match.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}
    graphData = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "others") && (i < 9) then
        if(deckname.has_key?(key))
          graphData.push({"category" => deckname[key], "column-1" => value})
        else
          graphData.push({"category" => key, "column-1" => value})
        end
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      graphData.push({"category" => deckname["others"], "column-1" => others_val})
    end

    return graphData
  end

  # 相性表作成のための関数
  def calcRate(big, small)
    big_double = big.group(:mydeck, :oppdeck).count
    small_double = small.group(:mydeck, :oppdeck).count
    small_double.default = 0;
    returnData = Hash.new { |h,k| h[k] = {} }

    big_my = Hash.new(0)
    big_opp = Hash.new(0)
    small_my = Hash.new(0)
    small_opp = Hash.new(0)
    big = 0
    small = 0

    big_double.each{|key, val|
      wr = (small_double[key] * 100.to_f / val).round(1)
      returnData[key[0]][key[1]] = [wr, rateColor(wr)]

      big_my[key[0]] += val
      big_opp[key[1]] += val
      small_my[key[0]] += small_double[key]
      small_opp[key[1]] += small_double[key]
    }

    big_my.each{|key, val|
      wr = (small_my[key] * 100.to_f / val).round(1)
      returnData[key]["総計"] = [wr, rateColor(wr)]
      big += val
    }
    
    big_opp.each{|key, val|
      wr = (small_opp[key] * 100.to_f / val).round(1)
      returnData["総計"][key] = [wr, rateColor(wr)]
      small += small_opp[key]
    }

    wr = (small * 100.to_f / big).round(1)
    returnData["総計"]["総計"] = [wr, rateColor(wr)]

    return returnData
  end

  def rateColor(rate)
    if rate >= 55
      return 'blue'
    elsif rate <= 45
      return 'red'
    else
      return 'black'
    end
  end

  def mychart
    @account = current_account
    
    getDuelData()
    @data = @data.where(playerid: current_account.id)

    #デッキ分布のデータ作成
    gon.oppdecks_mychart = pieChartData(@data)

    #DP推移のデータ作成
    dpline = Array.new()
    i = 0
    for obj in @data do
      i += 1
      dpline.push({"category" => i, "column-1" => obj.dp})
    end
    gon.dpline_mychart = dpline

    #相性表
    myHash = @data.group(:mydeck).count.sort_by { |_, v| -v }.to_h
    oppHash = @data.group(:oppdeck).count.sort_by { |_, v| -v }.to_h
    @myDeckArray = myHash.keys
    @oppDeckArray = oppHash.keys
    if @oppDeckArray.include?("others")
      @oppDeckArray.delete("others")
      @oppDeckArray.push("others")
    end
    @myDeckArray.push("総計")
    @oppDeckArray.push("総計")

    @winRateHash = calcRate(@data, @data.where(victory: "win"))
    @leadingRateHash = calcRate(@data.where.not(order: nil), @data.where(order: "first"))
    @numberOfMatchHash = @data.group(:mydeck, :oppdeck).count
    myHash.each{|key1, val1|
      @numberOfMatchHash[[key1, "総計"]] = val1
    }
    oppHash.each{|key2, val2|
      @numberOfMatchHash[["総計", key2]] = val2
    }
    @numberOfMatchHash[["総計", "総計"]] = @data.count
    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  def mydata_csv
    getDuelData()
    @data = @data.where(playerid: current_account.id)
  end

  def totalchart
    getDuelData()

    #デッキ分布のデータ作成
    gon.oppdecks_totalchart = pieChartData(@data)

    #直近のデッキ分布のデータ作成
    @recentData = @data.where(created_at: (Time.now - 7200)..Float::INFINITY)
    gon.recent_oppdecks_totalchart = pieChartData(@recentData)

    #相性表
    myHash = @data.group(:mydeck).count.sort_by { |_, v| -v }.to_h
    oppHash = @data.group(:oppdeck).count.sort_by { |_, v| -v }.to_h
    myHash.default = 0;
    oppHash.default = 0;
    @myDeckArray = Array.new
    @oppDeckArray = Array.new
    i = 0
    oppHash.each{|key, val|
      if i < 10 && key != "others"
        @oppDeckArray.push(key)
      end
      i += 1
    }
    if oppHash.include?("others")
      @oppDeckArray.push("others")
    end
    i = 0
    myHash.each{|key, val|
      if i < 10
        @myDeckArray.push(key)
      end
      i += 1
    }
    @myDeckArray.push("総計")
    @oppDeckArray.push("総計")

    @winRateHash = calcRate(@data, @data.where(victory: "win"))
    @leadingRateHash = calcRate(@data.where.not(order: nil), @data.where(order: "first"))
    @numberOfMatchHash = @data.group(:mydeck, :oppdeck).count
    myHash.each{|key1, val1|
      @numberOfMatchHash[[key1, "総計"]] = val1
    }
    oppHash.each{|key2, val2|
      @numberOfMatchHash[["総計", key2]] = val2
    }
    @numberOfMatchHash[["総計", "総計"]] = @data.count

    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  #DC選択関係
  def dc
    if params[:dc] != nil then
      return params[:dc]
    else
      return "UNKOWN"
    end
  end
  helper_method :dc

  def deckList
    return Array.new
  end
  helper_method :deckList

  def edit
    @account = current_account
    @selectedData = MasterMatch.find(params[:id])
    @decks = CSV.read("#{Rails.root}/config_duellinks/master/"+params[:dc]+"/decks.csv")
    @decks.push(["自分で入力する"])

    #直前のDPを計算
    if @selectedData.victory == "win"
      @preDP = @selectedData.dp - @selectedData.dpChanging
    else
      @preDP = @selectedData.dp + @selectedData.dpChanging
    end
    gon.preDP = @preDP
    gon.dpChanging = @selectedData.dpChanging

    #初期値の設定
    @defaultMyDeck = "自分で入力する"
    @defaultOppDeck = "自分で入力する"
    deckname = ""
    @decks.each do |obj|
      deckname = (obj[1] == nil) ? obj[0] : obj[1]
      if deckname == @selectedData.mydeck
        @defaultMyDeck = @selectedData.mydeck
      end
      if deckname == @selectedData.oppdeck
        @defaultOppDeck = @selectedData.oppdeck
      end
    end
  end

  def update
    obj = MasterMatch.find(params[:id])
    obj.update(match_params)
    obj.tag = params[:dc]
    obj.save()
    dpUpdate()
    redirect_to action: :mychart
  end

  def delete
    obj = MasterMatch.find(params[:id])
    if obj.playerid == current_account.id then
      obj.destroy
      dpUpdate()
    end
    redirect_to action: :mychart
  end

  private
  def match_params
    params.require(:master_match).permit(:mydeck, :oppdeck, :victory, :dp, :dpChanging, :order)
  end

  def dpUpdate
    data = MasterMatch.where(tag: params[:dc]).where(playerid: current_account.id)
    preDP = 0
    nowDP = 0
    for obj in data do
      if obj.victory == "win" then
        nowDP = preDP + obj.dpChanging
      else 
        nowDP = preDP - obj.dpChanging
        if nowDP < 0 then
          nowDP = 0
        end
      end
      if nowDP != obj.dp then
        obj.dp = nowDP
        obj.save
      end
      preDP = nowDP
    end
  end
end