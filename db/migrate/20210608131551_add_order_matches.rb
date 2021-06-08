class AddOrderMatches < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :order, :string
  end
end
