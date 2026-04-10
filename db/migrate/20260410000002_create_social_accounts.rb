class CreateSocialAccounts < ActiveRecord::Migration[7.2]
  def change
    create_table :social_accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :username
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at
      t.jsonb :extra_data, default: {}
      t.timestamps
    end

    add_index :social_accounts, [:user_id, :provider], unique: true
    add_index :social_accounts, [:provider, :uid], unique: true
  end
end
