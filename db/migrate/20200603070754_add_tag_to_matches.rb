class AddTagToMatches < ActiveRecord::Migration[5.2]
  def change
    add_column :matches, :tag, :string
  end
end
