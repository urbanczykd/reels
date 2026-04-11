class DetectAudioDurationJob < ApplicationJob
  queue_as :default

  def perform(soundtrack_id)
    soundtrack = Soundtrack.find(soundtrack_id)
    return unless soundtrack.audio_file.attached?

    Tempfile.create(["audio", File.extname(soundtrack.audio_file.filename.to_s)]) do |tmp|
      tmp.binmode
      tmp.write(soundtrack.audio_file.download)
      tmp.flush

      output = `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "#{tmp.path}" 2>&1`
      seconds = output.strip.to_f.round
      soundtrack.update!(duration_seconds: seconds) if seconds > 0
    end
  rescue => e
    Rails.logger.error("DetectAudioDurationJob failed: #{e.message}")
  end
end
