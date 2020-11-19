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

      dp = 0
      if Match.where(tag: kc()).where(playerid: current_account.id).exists? then
        dp = Match.where(tag: kc()).where(playerid: current_account.id).last.dp
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
    dpline.push({"category" => 0, "column-1" => 0})
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
    @data = Match.where(tag: kc()).where(playerid: current_account.id).where(created_at: datetime_detail()[0]..datetime_detail()[1])
  end

  def totalchart
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
      return "KC2020Nov"
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

    #初期値の設定
    @defaultMyDeck = "自分で入力する"
    @defaultMySkill = "自分で入力する"
    @defaultOppDeck = "自分で入力する"
    @defaultOppSkill = "自分で入力する"
    @decks.each do |obj|
      if obj[0] == @selectedData.mydeck
        @defaultMyDeck = @selectedData.mydeck
      end
      if obj[0] == @selectedData.oppdeck
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

    #相性表のデータ作成
    ahash1 = @mydata.group(:oppdeck).count
    ahash2 = @oppdata.group(:mydeck).count
    allHash = ahash1.merge(ahash2) {|key, oldval, newval| oldval + newval}
    allHash = allHash.sort {|a,b| b[1]<=>a[1]}.to_h
    whash1 = @mydata.where(victory: "勝ち").group(:oppdeck).count
    whash2 = @oppdata.where(victory: "負け").group(:mydeck).count
    winHash = whash1.merge(whash2) {|key, oldval, newval| oldval + newval}
    @winRateHash = Hash.new()
    allcount = 0
    wincount = 0
    allHash.each do |obj|
      if winHash.has_key?(obj[0])
        @winRateHash[obj[0]] = (winHash[obj[0]] * 100.to_f / obj[1]).round(1)
        wincount += winHash[obj[0]]
      else
        @winRateHash[obj[0]] = 0
      end
      allcount += allHash[obj[0]]
    end
    @winRateHash["総計"] = (wincount * 100.to_f / allcount).round(1)

    #スキルリスト
    oppskills = @oppdata.group(:oppskill).count.sort {|a,b| b[1]<=>a[1]}
    skilllist = Array.new()
    i = 0
    oppskills.each{|key, value|
      skilllist.push({"category" => key, "column-1" => value})
    }
    gon.skilllist = skilllist
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

  def user_list
    @account = current_account
    @data = Account.all
  end

  private
  def match_params
    params.require(:match).permit(:mydeck, :myskill, :oppdeck, :oppskill, :victory, :dpChanging)
  end

  def dpUpdate
    data = Match.where(tag: kc()).where(playerid: current_account.id)
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
