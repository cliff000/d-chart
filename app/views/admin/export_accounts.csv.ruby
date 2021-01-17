require 'csv'

CSV.generate(encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv|
  csv_column_names = %w(id, 
                        email, 
                        encrypted_password, 
                        reset_password_token, 
                        reset_password_sent_at, 
                        remember_created_at, 
                        created_at, 
                        updated_at)

  csv << csv_column_names
  @allAccounts.each do |obj|
    csv_column_values = [
      obj.id,
      obj.email,
      obj.encrypted_password,
      obj.reset_password_token,
      obj.reset_password_sent_at,
      obj.remember_created_at,
      obj.created_at,
      obj.updated_at
    ]
    csv << csv_column_values
  end
end