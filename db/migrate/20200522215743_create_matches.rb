class CreateMatches < ActiveRecord::Migration[5.2]
  def change
    create_table :matches do |t|
      t.text :mydeck
      t.text :myskill
      t.text :oppdeck
      t.text :oppskill
      t.text :victory
      t.integer :dp

      t.timestamps
    end
  end
end
