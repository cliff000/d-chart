# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

CSV.foreach('/webapp/db/csv/accounts.csv', headers: true) do |row|
    account = Account.new
    account.id = row['id']
    account.email = row['email']
    account.password = 'password'
    account.created_at = row['created_at']
    account.updated_at = row['updated_at']
    account.save!
end


CSV.foreach('/webapp/db/csv/matches.csv', headers: true) do |row|
    Match.create(
        id: row['id'],
        playerid: row['playerid'],
        mydeck: row['mydeck'],
        myskill: row['myskill'],
        oppdeck: row['oppdeck'],
        oppskill: row['oppskill'],
        victory: row['victory'],
        dp: row['dp'],
        created_at: row['created_at'],
        updated_at: row['updated_at'],
        tag: row['tag'],
        dpChanging: row['dpChanging']
    )
end