class ChangeDefaultMaster < ActiveRecord::Migration[5.2]
  def change
    change_column_default :master_matches, :dpChanging, from: nil, to: 1000
  end
end
