# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

Match.create(playerid:1, mydeck:'六武衆', myskill:'粉砕！', oppdeck:'ES召喚獣', oppskill:'ディスティニー・ドロー', victory:'勝ち', dp:+1000)
Match.create(playerid:2, mydeck:'六武衆', myskill:'粉砕！', oppdeck:'ES召喚獣', oppskill:'ディスティニー・ドロー', victory:'負け', dp:-1000)
Match.create(playerid:1, mydeck:'六武衆', myskill:'粉砕！', oppdeck:'サイバー・ドラゴン', oppskill:'サイバー流奥義', victory:'勝ち', dp:+1000)