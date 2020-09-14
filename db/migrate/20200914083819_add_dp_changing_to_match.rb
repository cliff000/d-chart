class AddDpChangingToMatch < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :dpChanging, :integer, default: 1000
  end
end
