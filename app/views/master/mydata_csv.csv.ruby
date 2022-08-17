require 'csv'

CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
  csv_column_names = %w(Create_at MyDeck OpponentDeck Victory Order DP)

  csv << csv_column_names
  @data.each do |obj|
    csv_column_values = [
      obj.created_at,
      obj.mydeck,
      obj.oppdeck,
      obj.victory,
      obj.order,
      obj.dp
    ]
    csv << csv_column_values
  end
end