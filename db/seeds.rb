# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

CSV.foreach('db/seeds/csv/accounts.csv', headers: true) do |row|
    Account.create(
        id: row['id'],
        email: row['email'],
        encrypted_password: row['encrypted_password'],
        reset_password_token: row['reset_password_token'],
        reset_password_sent_at: row['reset_password_sent_at'],
        remember_created_at: row['remember_created_at'],
        created_at: row['created_at'],
        updated_at: row['updated_at'],
        confirmation_token: row['confirmation_token'],
        confirmed_at: row['confirmed_at'],
        confirmation_sent_at: row['confirmation_sent_at'],
        unconfirmed_email: row['unconfirmed_email']
    )
end

CSV.foreach('db/seeds/csv/matches.csv', headers: true) do |row|
    Match.create(
        id: row['id'],
        playerid :row['playerid'],
        mydeck: row['mydeck'],
        myskill: row['myskill'],
        oppdeck: row['oppdeck'],
        oppskill :row['oppskill'],
        victory :row['victory'],
        dp :row['dp'],
        created_at :row['created_at'],
        updated_at :row['updated_at'],
        tag :row['tag'],
        dpChanging :row['dpChanging']
    )
end