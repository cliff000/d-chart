class CreateMasterMatches < ActiveRecord::Migration[5.2]
  def change
    create_table :master_matches do |t|
      t.integer :playerid
      t.text :mydeck
      t.text :oppdeck
      t.text :victory
      t.integer :dp
      t.integer :dpChanging
      t.text :order

      t.timestamps
    end
  end
end
