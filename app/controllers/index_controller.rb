class IndexController < ApplicationController
    layout 'index'

    def introduction
    end

    def past_kc
    end

    def past_kc_chart
        @data = Match.where(tag: params[:kcname])
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
        gon.past_kc_chart = oppdecks2

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
end
