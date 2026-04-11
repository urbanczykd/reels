class CreateSoundtracks < ActiveRecord::Migration[7.2]
  def change
    create_table :soundtracks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :duration_seconds
      t.timestamps
    end
  end
end
