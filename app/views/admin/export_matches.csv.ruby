require 'csv'

CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
  csv_column_names = %w(id, 
                        playerid, 
                        mydeck, 
                        myskill, 
                        oppdeck, 
                        oppskill, 
                        victory, 
                        dp, 
                        created_at, 
                        updated_at, 
                        tag, 
                        dpChanging)

  csv << csv_column_names
  @allMatches.each do |obj|
    csv_column_values = [
      obj.id,
      obj.playerid,
      obj.mydeck,
      obj.myskill,
      obj.oppdeck,
      obj.oppskill,
      obj.victory,
      obj.dp,
      obj.created_at,
      obj.updated_at,
      obj.tag,
      obj.dpChanging
    ]
    csv << csv_column_values
  end
end