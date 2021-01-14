class AddColumnToAccount < ActiveRecord::Migration[5.2]
  def change
    add_column  :account,  :confirmation_token,  :string
    add_column  :account,  :confirmed_at,        :datetime
    add_column  :account,  :confirmation_sent_at,:datetime    
    add_column  :account,  :unconfirmed_email,   :string       #email変更時の認証が不要であれば、この項目は必要ではありません。ただし、configの「reconfirmable」を「false」にする必要があります。
  end
end
