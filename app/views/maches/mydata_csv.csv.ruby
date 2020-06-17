require 'csv'

CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
  csv_column_names = %w(タイムスタンプ 自分デッキ 自分スキル 相手デッキ, 相手スキル, 勝敗, DP)

  csv << csv_column_names
  @data.each do |obj|
    csv_column_values = [
      obj.created_at,
      obj.mydeck,
      obj.myskill,
      obj.oppdeck,
      obj.oppskill,
      obj.victory,
      obj.dp
    ]
    csv << csv_column_values
  end
end