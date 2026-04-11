class GenerateClipJob < ApplicationJob
  queue_as :default

  def perform(clip_id)
    clip = Clip.find(clip_id)
    return unless clip.pending? || clip.failed?

    clip.mark_processing!
    clip.update_column(:generation_progress, 5)

    # AI caption
    begin
      result = OllamaService.generate_caption_and_hashtags(clip.title, clip.description)
      clip.update!(ai_caption: result[:caption], ai_hashtags: result[:hashtags])
    rescue => e
      Rails.logger.warn("AI caption failed, continuing: #{e.message}")
    end
    clip.update_column(:generation_progress, 20)

    # Generate video (service updates progress 20→95 internally)
    VideoGeneratorService.new(clip).call

    clip.update_column(:generation_progress, 100)
    clip.mark_ready!
  rescue => e
    Rails.logger.error("GenerateClipJob failed for clip #{clip_id}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    clip&.mark_failed!(e.message)
  end
end
