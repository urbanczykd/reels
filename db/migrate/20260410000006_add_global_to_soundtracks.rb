class AddGlobalToSoundtracks < ActiveRecord::Migration[7.2]
  def change
    add_column :soundtracks, :global, :boolean, default: false, null: false
    change_column_null :soundtracks, :user_id, true
  end
end
