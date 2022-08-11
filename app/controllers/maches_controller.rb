require 'csv'
require "json"

class MachesController < ApplicationController
  layout 'maches'
  before_action :authenticate_account!

  @TIMEMIN = "2000-01-01T00:00"
  @TIMEMAX = "2200-01-01T00:00"

  def form
    @match = Match.new
    @lastData = Match.where(tag: params[:kc]).where(playerid: current_account.id).last
    @decks = CSV.read("#{Rails.root}/config_duellinks/"+params[:kc]+"/decks.csv")
    @skills = CSV.read("#{Rails.root}/config_duellinks/"+params[:kc]+"/skills.csv")
    @decks.push(["自分で入力する"])
    @skills.push(["自分で入力する"])

    #初期値の設定
    @defaultDeck = "自分で入力する"
    @defaultSkill = "自分で入力する"
    if @lastData.nil?
      @defaultDeck = ""
      @defaultSkill = ""
      gon.lastdp = 0
    else
      @decks.each do |obj|
        deckname = (obj[1] == nil) ? obj[0] : obj[1]
        if deckname == @lastData.mydeck
          @defaultDeck = @lastData.mydeck
          break
        end
      end
      @skills.each do |obj|
        if obj[0] == @lastData.myskill
          @defaultSkill = @lastData.myskill
          break
        end
        gon.lastdp = @lastData.dp
      end
    end

    #スキルリスト読み込み
    File.open("#{Rails.root}/config_duellinks/"+params[:kc]+"/major_skill.json") do |file|
      gon.major_skill = JSON.load(file)
    end

    #KC区間取得
    tmp_json = {}
    File.open("#{Rails.root}/config_duellinks/"+params[:kc]+"/datetime.json") do |file|
      tmp_json = JSON.load(file)
    end
    kcRange = [Time.parse(tmp_json["1日目"][0]), Time.parse(tmp_json["4日目"][1])]
    @inKC = true
    if Time.now < kcRange[0] || Time.now > kcRange[1]
      @inKC = false
    end
  end

  def sended_form
    @lastData = Match.where(playerid: current_account.id).last
  end

  def create
    if request.post? then
      tmp = Match.new(match_params)
      tmp.playerid = current_account.id

      dpChanging = 0
      if Match.where(tag: params[:kc]).where(playerid: current_account.id).exists? then
        dpChanging = tmp.dp - Match.where(tag: params[:kc]).where(playerid: current_account.id).last.dp
      else 
        dpChanging = tmp.dp
      end
      if dpChanging < 0
        dpChanging = dpChanging * -1
      end
      tmp.dpChanging = dpChanging
      tmp.tag = params[:kc]
      tmp.save
    end
    redirect_to action: :sended_form
  end

  def getDuelData
    @data = Match.where(tag: params[:kc])

    # 先行後攻絞り込み
    @order = ""
    if(params[:order] != nil && params[:order] != "")
      @order = params[:order]
      @data = @data.where(order: @order)
    end

    #KC区間取得
    tmp_json = {}
    File.open("#{Rails.root}/config_duellinks/"+params[:kc]+"/datetime.json") do |file|
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
    others_val = 0
    oppdecks = @data.group(:oppdeck).count.sort {|a,b| b[1]<=>a[1]}
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

    #相性表
    myHash = @data.group(:mydeck).count
    oppHash = @data.group(:oppdeck).count
    myHash = myHash.sort_by { |_, v| -v }.to_h
    oppHash = oppHash.sort_by { |_, v| -v }.to_h
    @myDeckArray = Array.new()
    @oppDeckArray = Array.new()
    doubleMy = @data.group(:mydeck, :oppdeck).count
    winData = @data.where(victory: "勝ち")
    myWinHash = winData.group(:mydeck).count
    myWinHash2 = winData.group(:oppdeck).count
    doubleMyWin = winData.group(:mydeck, :oppdeck).count
    odata = @data.where.not(order: nil)
    omyHash = odata.group(:mydeck).count
    ooppHash = odata.group(:oppdeck).count
    odoubleMy = odata.group(:mydeck, :oppdeck).count
    leadingData = @data.where(order: "先行")
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
    if @oppDeckArray.include?("その他")
      @oppDeckArray.delete("その他")
      @oppDeckArray.push("その他")
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

  def mydata_csv
    @data = Match.where(tag: params[:kc]).where(playerid: current_account.id).where(created_at: datetime_detail()[0]..datetime_detail()[1])
  end

  def totalchart
    getDuelData()
    
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


    #相性表
    myHash = @data.group(:mydeck).count
    oppHash = @data.group(:oppdeck).count
    oppHash = oppHash.sort_by { |_, v| -v }.to_h
    @deckArray = Array.new()
    doubleMy = @data.group(:mydeck, :oppdeck).count
    doubleOpp = @data.group(:oppdeck, :mydeck).count
    doubleAll = doubleOpp.merge(doubleMy) {|key, oldval, newval| oldval + newval}
    winData = @data.where(victory: "勝ち")
    loseData = @data.where(victory: "負け")
    myWinHash = winData.group(:mydeck).count
    oppWinHash = loseData.group(:oppdeck).count
    allWinHash = oppWinHash.merge(myWinHash) {|key, oldval, newval| oldval + newval}
    doubleMyWin = winData.group(:mydeck, :oppdeck).count
    doubleOppWin = loseData.group(:oppdeck, :mydeck).count
    doubleAllWin = doubleOppWin.merge(doubleMyWin) {|key, oldval, newval| oldval + newval}

    
    @winRateHash = Hash.new { |h,k| h[k] = {} }
    i = 0
    j = 0
    oppHash.each{|key1, val1|
      break if i > 9
      j = 0
      oppHash.each{|key2, val2|
        break if j > 9
        win_num = doubleAllWin.has_key?([key1, key2]) ? doubleAllWin[[key1, key2]] : 0
        if doubleAll.has_key?([key1, key2])
          @winRateHash[key1][key2] = (win_num * 100.to_f / doubleAll[[key1, key2]]).round(1)
        end
        j += 1
      }
      win_num = allWinHash.has_key?(key1) ? allWinHash[key1] : 0
      match_num = myHash.has_key?(key1) ? myHash[key1] + val1 : val1
      @winRateHash[key1]["総計"] = (win_num * 100.to_f / match_num).round(1)
      @winRateHash["総計"][key1] = ((match_num - win_num) * 100.to_f / match_num).round(1)
      @deckArray.push(key1)
      i += 1
    }
    if @deckArray.include?("その他")
      @deckArray.delete("その他")
      @deckArray.push("その他")
    end
    @deckArray.push("総計")
    @winRateHash["総計"]["総計"] = 50.0

    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  #KC選択関係
  def kc
    if params[:kc] != nil then
      return params[:kc]
    else
      return "UNKOWN"
    end
  end
  helper_method :kc

  def deckList
    if params[:kc] != nil
      return CSV.read("#{Rails.root}/config_duellinks/"+params[:kc]+"/decks.csv")
    else
      return Array.new
    end
  end
  helper_method :deckList

  def edit
    @account = current_account
    @selectedData = Match.find(params[:id])
    @decks = CSV.read("#{Rails.root}/config_duellinks/"+params[:kc]+"/decks.csv")
    @skills = CSV.read("#{Rails.root}/config_duellinks/"+params[:kc]+"/skills.csv")
    @decks.push(["自分で入力する"])
    @skills.push(["自分で入力する"])

    #直前のDPを計算
    if @selectedData.victory == "勝ち"
      @preDP = @selectedData.dp - @selectedData.dpChanging
    else
      @preDP = @selectedData.dp + @selectedData.dpChanging
    end
    gon.preDP = @preDP
    gon.dpChanging = @selectedData.dpChanging

    #初期値の設定
    @defaultMyDeck = "自分で入力する"
    @defaultMySkill = "自分で入力する"
    @defaultOppDeck = "自分で入力する"
    @defaultOppSkill = "自分で入力する"
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
    @skills.each do |obj|
      if obj[0] == @selectedData.myskill
        @defaultMySkill = @selectedData.myskill
      end
      if obj[0] == @selectedData.oppskill
        @defaultOppSkill = @selectedData.oppskill
      end
    end
  end

  def update
    obj = Match.find(params[:id])
    obj.update(match_params)
    obj.tag = params[:kc]
    obj.save()
    dpUpdate()
    redirect_to action: :mychart
  end

  def deckchart
    getDuelData()
    @deckName = URI.unescape(params[:deck])
    @mydata = @data.where(mydeck: params[:deck])
    @oppdata = @data.where(oppdeck: params[:deck])
    
    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end

    #相性表
    mysHash = @mydata.group(:myskill).count
    oppsHash = @oppdata.group(:oppskill).count
    skillHash = oppsHash.merge(mysHash) {|key, oldval, newval| oldval + newval}
    skillHash = skillHash.sort_by { |_, v| -v }.to_h

    oppdHash = @mydata.group(:oppdeck).count
    mydHash = @oppdata.group(:mydeck).count
    deckHash = oppdHash.merge(mydHash) {|key, oldval, newval| oldval + newval}
    deckHash = deckHash.sort_by { |_, v| -v }.to_h

    doubleMy = @mydata.group(:myskill, :oppdeck).count
    doubleOpp = @oppdata.group(:oppskill, :mydeck).count
    doubleAll = doubleOpp.merge(doubleMy) {|key, oldval, newval| oldval + newval}
    winData = @mydata.where(victory: "勝ち")
    loseData = @oppdata.where(victory: "負け")
    myWinHash = winData.group(:myskill).count
    oppWinHash = loseData.group(:oppskill).count
    allWinHash = oppWinHash.merge(myWinHash) {|key, oldval, newval| oldval + newval}
    doubleMyWin = winData.group(:myskill, :oppdeck).count
    doubleOppWin = loseData.group(:oppskill, :mydeck).count
    doubleAllWin = doubleOppWin.merge(doubleMyWin) {|key, oldval, newval| oldval + newval}

    @winRateHash = Hash.new { |h,k| h[k] = {} }
    @skillArray = Array.new
    @deckArray = Array.new
    i = 0
    j = 0
    skillHash.each{|key1, val1|
      break if i > 2
      j = 0
      deckHash.each{|key2, val2|
        break if j > 10
        if doubleAll.has_key?([key1, key2])
          win_num = doubleAllWin.has_key?([key1, key2]) ? doubleAllWin[[key1, key2]] : 0
          @winRateHash[key1][key2] = (win_num * 100.to_f / doubleAll[[key1, key2]]).round(1)
        else
          @winRateHash[key1][key2] = -1
        end
        if i == 0
          @deckArray.push(key2)
        end
        j += 1
      }
      win_num = allWinHash.has_key?(key1) ? allWinHash[key1] : 0
      @winRateHash[key1]["総計"] = (win_num * 100.to_f / val1).round(1)
      @skillArray.push(key1)
      i += 1
    }
    @deckArray.push("総計")

    #スキルリスト
    oppskills = @oppdata.group(:oppskill).order(count_all: :desc).count
    others_val = 0
    skilllist = Array.new()
    i = 0
    oppskills.each{|key, value|
      if !(key == "その他") && (i < 3) then
        skilllist.push({"category" => key, "column-1" => value})
        i += 1
      else
        others_val += value
      end
    }
    if !(others_val == 0) then
      skilllist.push({"category" => "その他", "column-1" => others_val})
    end
    gon.skilllist = skilllist
  end

  def delete
    obj = Match.find(params[:id])
    if obj.playerid == current_account.id then
      obj.destroy
      dpUpdate()
    end
    redirect_to action: :mychart
  end

  def import
    Match.import(params[:file])
    redirect_to "/admin/import"
  end

  private
  def match_params
    params.require(:match).permit(:mydeck, :myskill, :oppdeck, :oppskill, :victory, :dp, :dpChanging, :order)
  end

  def dpUpdate
    data = Match.where(tag: params[:kc]).where(playerid: current_account.id)
    preDP = 0
    nowDP = 0
    for obj in data do
      if obj.victory == "勝ち" then
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
