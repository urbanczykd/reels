class GenerateClipJob < ApplicationJob
  queue_as :default

  def perform(clip_id)
    clip = Clip.find(clip_id)
    return unless clip.pending? || clip.failed?

    clip.mark_processing!

    # Generate AI caption first
    begin
      result = OllamaService.generate_caption_and_hashtags(clip.title, clip.description)
      clip.update!(ai_caption: result[:caption], ai_hashtags: result[:hashtags])
    rescue => e
      Rails.logger.warn("AI caption failed, continuing: #{e.message}")
    end

    # Generate video
    VideoGeneratorService.new(clip).call

    clip.mark_ready!
  rescue => e
    Rails.logger.error("GenerateClipJob failed for clip #{clip_id}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    clip&.mark_failed!(e.message)
  end
end
