class AddGenerationProgressToClips < ActiveRecord::Migration[7.2]
  def change
    add_column :clips, :generation_progress, :integer, default: 0, null: false
  end
end
