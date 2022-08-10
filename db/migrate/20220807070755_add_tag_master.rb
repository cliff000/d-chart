class AddTagMaster < ActiveRecord::Migration[5.2]
  def change
    add_column :master_matches, :tag, :string
  end
end
