class AddPlayeridToMatch < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :playerid, :integer
  end
end
