class CreateClips < ActiveRecord::Migration[7.2]
  def change
    create_table :clips do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, default: "pending"
      t.integer :duration, default: 7
      t.string :transition_effect, default: "fade"
      t.text :ai_caption
      t.text :ai_hashtags
      t.jsonb :upload_results, default: {}
      t.text :error_message
      t.timestamps
    end
  end
end
