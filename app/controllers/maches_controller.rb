require 'csv'
require "json"

class MachesController < ApplicationController
  layout 'maches'
  before_action :authenticate_account!

  $kc = Hash.new()
  $datetime = Hash.new()
  $dprange = Hash.new()

  def index
    @account = current_account
    @msg = 'account created at: ' + @account.created_at.to_s
    @lastData = Match.last
  end

  def form
    @match = Match.new
    @lastData = Match.where(tag: kc()).where(playerid: current_account.id).last
    @decks = CSV.read("#{Rails.root}/config_duellinks/"+kc()+"/decks.csv")
    @skills = CSV.read("#{Rails.root}/config_duellinks/"+kc()+"/skills.csv")
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
        if obj[0] == @lastData.mydeck
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
    File.open("#{Rails.root}/config_duellinks/"+kc()+"/major_skill.json") do |file|
      gon.major_skill = JSON.load(file)
    end

    #KC区間取得
    tmp_json = {}
    File.open("#{Rails.root}/config_duellinks/"+kc()+"/datetime.json") do |file|
      tmp_json = JSON.load(file)
    end
    @kcRange = [Time.parse(tmp_json["1日目"][0]), Time.parse(tmp_json["4日目"][1])]
    @now = Time.now

    
  end

  def sended_form
    @lastData = Match.where(playerid: current_account.id).last
  end

  def create
    if request.post? then
      tmp = Match.new(match_params)
      tmp.playerid = current_account.id

      dpChanging = 0
      if Match.where(tag: kc()).where(playerid: current_account.id).exists? then
        dpChanging = tmp.dp - Match.where(tag: kc()).where(playerid: current_account.id).last.dp
      else 
        dpChanging = tmp.dp
      end
      if dpChanging < 0
        dpChanging = dpChanging * -1
      end
      tmp.dpChanging = dpChanging
      tmp.tag = kc()
      tmp.save
    end
    redirect_to action: :sended_form
  end

  def test
  end

  def mychart
    @account = current_account
    @data = Match.where(tag: kc()).where(playerid: current_account.id).where(created_at: datetime_detail()[0]..datetime_detail()[1])
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

    @winRateHash = Hash.new { |h,k| h[k] = {} }
    i = 0
    j = 0
    myHash.each{|key1, val1|
      j = 0
      oppHash.each{|key2, val2|
        win_num = doubleMyWin.has_key?([key1, key2]) ? doubleMyWin[[key1, key2]] : 0
        if doubleMy.has_key?([key1, key2])
          @winRateHash[key1][key2] = (win_num * 100.to_f / doubleMy[[key1, key2]]).round(1)
        else
          @winRateHash[key1][key2] = -1
        end
        j += 1
      }
      win_num = myWinHash.has_key?(key1) ? myWinHash[key1] : 0
      @winRateHash[key1]["総計"] = (win_num * 100.to_f / val1).round(1)
      @myDeckArray.push(key1)
      i += 1
    }
    oppHash.each{|key2, val2|
      win_num = myWinHash2.has_key?(key2) ? myWinHash2[key2] : 0
      @winRateHash["総計"][key2] = (win_num * 100.to_f / val2).round(1)
      @oppDeckArray.push(key2)
    }
    @myDeckArray.push("総計")
    @oppDeckArray.push("総計")
    @winRateHash["総計"]["総計"] = (winData.count * 100.to_f / @data.count).round(1)


    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  def mydata_csv
    @data = Match.where(tag: kc()).where(playerid: current_account.id).where(created_at: datetime_detail()[0]..datetime_detail()[1])
  end

  def totalchart
    @ip = request.remote_ip
    if params[:start] != nil && params[:end] != nil
      $dprange[current_account] = [params[:start], params[:end]]
    end

    @data = Match.where(tag: kc()).where(created_at: datetime_detail()[0]..datetime_detail()[1]).where(dp: dprange_num()[0]..dprange_num()[1])
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
    allHash = oppHash.merge(myHash) {|key, oldval, newval| oldval + newval}
    allHash = allHash.sort_by { |_, v| -v }.to_h
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
    allHash.each{|key1, val1|
      break if i > 10
      j = 0
      allHash.each{|key2, val2|
        break if j > 10
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
    @deckArray.push("総計")
    @winRateHash["総計"]["総計"] = 50.0

    #画像リスト読み込み
    @deck_image = {}
    File.open("#{Rails.root}/config_duellinks/deck_image.json") do |file|
      @deck_image = JSON.load(file)
    end
  end

  #KC選択関係
  def select_kc
    $kc[current_account] = params[:kc]
  end
  def kc
    if $kc.key?(current_account) then
      return $kc[current_account]
    else
      return "KC2021Sep"
    end
  end
  helper_method :kc

  def deckList
    return CSV.read("#{Rails.root}/config_duellinks/"+kc()+"/decks.csv")
  end
  helper_method :deckList

  #KC作成
  def create_kc
    @match = Match.new
  end

  #日付関係
  def select_datetime
    $datetime[current_account] = params[:datetime]
  end
  def datetime
    if $datetime.key?(current_account) then
      return $datetime[current_account]
    else
      return "全日程"
    end
  end
  def datetime_detail
    @tmp_json = {}
    File.open("#{Rails.root}/config_duellinks/"+kc()+"/datetime.json") do |file|
      @tmp_json = JSON.load(file)
    end

    if $datetime.key?(current_account) && $datetime[current_account] != "全日程" then
      return [Time.parse(@tmp_json[$datetime[current_account]][0]), Time.parse(@tmp_json[$datetime[current_account]][1])]
    else
      return [-Float::INFINITY, Float::INFINITY]
    end
  end
  helper_method :datetime
  helper_method :datetime_detail

  #DP範囲検索
  def select_dprange
    dr1 = params[:dprange1]
    dr2 = params[:dprange2]
    if number?(dr1) && number?(dr2)
      $dprange[current_account] = [dr1.to_i, dr2.to_i]
    else
      $dprange[current_account] = [nil, nil]
    end
  end
  def dprange_num
    if $dprange.key?(current_account) 
      if $dprange[current_account][0] != nil && $dprange[current_account][1] != nil
        return $dprange[current_account]
      else
        return [-Float::INFINITY, Float::INFINITY]
      end
    else
      return [-Float::INFINITY, Float::INFINITY]
    end
  end
  def dprange_str
    if $dprange.key?(current_account) 
      if $dprange[current_account][0] != nil && $dprange[current_account][1] != nil
        return [$dprange[current_account][0].to_s, $dprange[current_account][1].to_s]
      else
        return ["", ""]
      end
    else
      return ["", ""]
    end
  end
  helper_method :dprange_num
  helper_method :dprange_str

  # 文字列が数字だけで構成されていれば true を返す
  def number?(str)
    # 文字列の先頭(\A)から末尾(\z)までが「0」から「9」の文字か
    nil != (str =~ /\A[0-9]+\z/)
  end

  def edit
    @account = current_account
    @selectedData = Match.find(params[:id])
    @decks = CSV.read("#{Rails.root}/config_duellinks/"+kc()+"/decks.csv")
    @skills = CSV.read("#{Rails.root}/config_duellinks/"+kc()+"/skills.csv")
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
    obj.tag = kc()
    obj.save()
    dpUpdate()
    redirect_to action: :mychart
  end

  def deckchart
    @deckName = URI.unescape(params[:deck])
    @mydata = Match.where(tag: kc()).where(created_at: datetime_detail()[0]..datetime_detail()[1]).where(mydeck: params[:deck])
    @oppdata = Match.where(tag: kc()).where(created_at: datetime_detail()[0]..datetime_detail()[1]).where(oppdeck: params[:deck])
    
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
    data = Match.where(tag: kc()).where(playerid: current_account.id)
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
