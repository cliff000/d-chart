require 'csv'
require "json"

class MasterController < ApplicationController
  layout 'master'
  before_action :authenticate_account!

  @TIMEMIN = "2000-01-01T00:00"
  @TIMEMAX = "2200-01-01T00:00"

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

  def mychart
    @account = current_account
    
    getDuelData()
    @data = @data.where(playerid: current_account.id)

    #デッキ分布のデータ作成
    deckname = {}
    File.open("#{Rails.root}/config_duellinks/master/deckname_japanese.json") do |file|
      deckname = JSON.load(file)
    end
    others_val = 0
    oppdecks = @data.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}
    oppdecks2 = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "others") && (i < 9) then
        if(deckname.has_key?(key))
          oppdecks2.push({"category" => deckname[key], "column-1" => value})
        else
          oppdecks2.push({"category" => key, "column-1" => value})
        end
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      oppdecks2.push({"category" => deckname["others"], "column-1" => others_val})
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

    #相性表
    myHash = @data.group(:mydeck).count
    oppHash = @data.group(:oppdeck).count
    myHash = myHash.sort_by { |_, v| -v }.to_h
    oppHash = oppHash.sort_by { |_, v| -v }.to_h
    @myDeckArray = Array.new()
    @oppDeckArray = Array.new()
    doubleMy = @data.group(:mydeck, :oppdeck).count
    winData = @data.where(victory: "win")
    myWinHash = winData.group(:mydeck).count
    myWinHash2 = winData.group(:oppdeck).count
    doubleMyWin = winData.group(:mydeck, :oppdeck).count
    odata = @data.where.not(order: nil)
    omyHash = odata.group(:mydeck).count
    ooppHash = odata.group(:oppdeck).count
    odoubleMy = odata.group(:mydeck, :oppdeck).count
    leadingData = @data.where(order: "first")
    myLeadingHash = leadingData.group(:mydeck).count
    myLeadingHash2 = leadingData.group(:oppdeck).count
    doubleMyLeading = leadingData.group(:mydeck, :oppdeck).count

    @winRateHash = Hash.new { |h,k| h[k] = {} }
    @numberOfMatchHash = Hash.new { |h,k| h[k] = {} }
    @leadingRateHash = Hash.new { |h,k| h[k] = {} }
    i = 0
    j = 0
    myHash.each{|key1, val1|
      j = 0
      oppHash.each{|key2, val2|
        win_num = doubleMyWin.has_key?([key1, key2]) ? doubleMyWin[[key1, key2]] : 0
        if doubleMy.has_key?([key1, key2])
          # 勝率
          @winRateHash[key1][key2] = (win_num * 100.to_f / doubleMy[[key1, key2]]).round(1)
          # 対戦数
          @numberOfMatchHash[key1][key2] = doubleMy[[key1, key2]]
        end
        leading_num = doubleMyLeading.has_key?([key1, key2]) ? doubleMyLeading[[key1, key2]] : 0
        if odoubleMy.has_key?([key1, key2])
          # 先行率
          @leadingRateHash[key1][key2] = (leading_num * 100.to_f / odoubleMy[[key1, key2]]).round(1)
        end
        j += 1
      }
      win_num = myWinHash.has_key?(key1) ? myWinHash[key1] : 0
      leading_num = myLeadingHash.has_key?(key1) ? myLeadingHash[key1] : 0
      @winRateHash[key1]["総計"] = (win_num * 100.to_f / val1).round(1)
      @numberOfMatchHash[key1]["総計"] = val1
      if omyHash.has_key?(key1)
        @leadingRateHash[key1]["総計"] = (leading_num * 100.to_f / omyHash[key1]).round(1)
      end
      @myDeckArray.push(key1)
      i += 1
    }
    oppHash.each{|key2, val2|
      win_num = myWinHash2.has_key?(key2) ? myWinHash2[key2] : 0
      leading_num = myLeadingHash2.has_key?(key2) ? myLeadingHash2[key2] : 0
      @winRateHash["総計"][key2] = (win_num * 100.to_f / val2).round(1)
      @numberOfMatchHash["総計"][key2] = val2
      if ooppHash.has_key?(key2)
        @leadingRateHash["総計"][key2] = (leading_num * 100.to_f / ooppHash[key2]).round(1)
      end
      @oppDeckArray.push(key2)
    }
    @myDeckArray.push("総計")
    if @oppDeckArray.include?("others")
      @oppDeckArray.delete("others")
      @oppDeckArray.push("others")
    end
    @oppDeckArray.push("総計")
    @winRateHash["総計"]["総計"] = (winData.count * 100.to_f / @data.count).round(1)
    @numberOfMatchHash["総計"]["総計"] = @data.count
    @leadingRateHash["総計"]["総計"] = (leadingData.count * 100.to_f / odata.count).round(1)

    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  def totalchart
    getDuelData()

    #デッキ分布のデータ作成
    deckname = {}
    File.open("#{Rails.root}/config_duellinks/master/deckname_japanese.json") do |file|
      deckname = JSON.load(file)
    end
    others_val = 0
    oppdecks = @data.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}
    oppdecks2 = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "others") && (i < 9) then
        if(deckname.has_key?(key))
          oppdecks2.push({"category" => deckname[key], "column-1" => value})
        else
          oppdecks2.push({"category" => key, "column-1" => value})
        end
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      oppdecks2.push({"category" => deckname["others"], "column-1" => others_val})
    end
    gon.oppdecks_totalchart = oppdecks2

    #直近のデッキ分布のデータ作成
    @recentData = @data.where(created_at: (Time.now - 7200)..Float::INFINITY)
    oppdecks = @recentData.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}
    others_val = 0
    oppdecks2 = Array.new()
    i = 0
    oppdecks.each{|key, value|
      if !(key == "others") && (i < 9) then
        if(deckname.has_key?(key))
          oppdecks2.push({"category" => deckname[key], "column-1" => value})
        else
          oppdecks2.push({"category" => key, "column-1" => value})
        end
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      oppdecks2.push({"category" => deckname["others"], "column-1" => others_val})
    end
    gon.recent_oppdecks_totalchart = oppdecks2


    #相性表
    myHash = @data.group(:mydeck).count
    oppHash = @data.group(:oppdeck).count
    allHash = oppHash.merge(myHash) {|key, oldval, newval| oldval + newval}
    allHash = allHash.sort_by { |_, v| -v }.to_h
    @deckArray = Array.new()
    doubleMy = @data.group(:mydeck, :oppdeck).count
    doubleOpp = @data.group(:oppdeck, :mydeck).count
    doubleAll = doubleOpp.merge(doubleMy) {|key, oldval, newval| oldval + newval}
    winData = @data.where(victory: "win")
    loseData = @data.where(victory: "lose")
    myWinHash = winData.group(:mydeck).count
    oppWinHash = loseData.group(:oppdeck).count
    allWinHash = oppWinHash.merge(myWinHash) {|key, oldval, newval| oldval + newval}
    doubleMyWin = winData.group(:mydeck, :oppdeck).count
    doubleOppWin = loseData.group(:oppdeck, :mydeck).count
    doubleAllWin = doubleOppWin.merge(doubleMyWin) {|key, oldval, newval| oldval + newval}

    
    @winRateHash = Hash.new { |h,k| h[k] = {} }
    i = 0
    j = 0
    allHash.each{|key1, val1|
      break if i > 9
      j = 0
      allHash.each{|key2, val2|
        break if j > 9
        win_num = doubleAllWin.has_key?([key1, key2]) ? doubleAllWin[[key1, key2]] : 0
        if doubleAll.has_key?([key1, key2])
          @winRateHash[key1][key2] = (win_num * 100.to_f / doubleAll[[key1, key2]]).round(1)
        else
          @winRateHash[key1][key2] = -1
        end
        j += 1
      }
      win_num = allWinHash.has_key?(key1) ? allWinHash[key1] : 0
      @winRateHash[key1]["総計"] = (win_num * 100.to_f / val1).round(1)
      @winRateHash["総計"][key1] = (win_num * 100.to_f / val1).round(1)
      @deckArray.push(key1)
      i += 1
    }
    if @deckArray.include?("others")
      @deckArray.delete("others")
      @deckArray.push("others")
    end
    @deckArray.push("総計")
    @winRateHash["総計"]["総計"] = 50.0

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
      return "DC2022Aug"
    end
  end
  helper_method :dc

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
    obj.update(master_match_params)
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