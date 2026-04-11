class VideoGeneratorService
  REEL_WIDTH  = 1080
  REEL_HEIGHT = 1920
  FPS = 30
  TRANSITION_DURATION = 0.4

  XFADE_TRANSITIONS = {
    "fade"    => "fade",
    "zoom"    => "zoomin",
    "slide"   => "slideleft",
    "dissolve" => "dissolve"
  }.freeze

  def initialize(clip)
    @clip = clip
  end

  def call
    prepare_temp_dir
    download_images
    download_audio if @clip.soundtrack&.audio_file&.attached?
    generate_video
    attach_video
  ensure
    cleanup
  end

  private

  def prepare_temp_dir
    @temp_dir = Rails.root.join("tmp", "clip_#{@clip.id}_#{Time.now.to_i}").to_s
    FileUtils.mkdir_p(@temp_dir)
    @output_path = File.join(@temp_dir, "output.mp4")
  end

  def download_images
    @image_paths = []
    @clip.images.each_with_index do |img, i|
      path = File.join(@temp_dir, "image_#{i.to_s.rjust(3, "0")}.jpg")
      File.open(path, "wb") { |f| f.write(img.download) }
      @image_paths << path
    end
  end

  def download_audio
    ext = File.extname(@clip.soundtrack.audio_file.filename.to_s).presence || ".mp3"
    @audio_path = File.join(@temp_dir, "audio#{ext}")
    File.open(@audio_path, "wb") { |f| f.write(@clip.soundtrack.audio_file.download) }
  rescue => e
    Rails.logger.warn("Audio download failed, continuing without audio: #{e.message}")
    @audio_path = nil
  end

  def generate_video
    n = @image_paths.size
    # Each image gets equal time; overlap region is shared with xfade
    duration_per_image = @clip.duration.to_f / n

    transition = XFADE_TRANSITIONS.fetch(@clip.transition_effect, "fade")
    td = TRANSITION_DURATION

    # Build ffmpeg args: one -loop 1 -t <dur> -i <img> per image
    input_args = @image_paths.flat_map { |p| ["-loop", "1", "-t", duration_per_image.round(3).to_s, "-i", p] }

    # Build filter_complex:
    #   1. Scale+pad every stream to 1080x1920
    #   2. Chain xfade between consecutive streams
    filter_lines = []

    # Scale each input to reel dimensions
    @image_paths.each_with_index do |_, i|
      filter_lines << "[#{i}:v]scale=#{REEL_WIDTH}:#{REEL_HEIGHT}:force_original_aspect_ratio=decrease," \
                      "pad=#{REEL_WIDTH}:#{REEL_HEIGHT}:(ow-iw)/2:(oh-ih)/2:color=black," \
                      "setsar=1,fps=#{FPS}[v#{i}]"
    end

    if n == 1
      # Single image — just fade in/out
      filter_lines << "[v0]fade=t=in:st=0:d=#{td},fade=t=out:st=#{(duration_per_image - td).round(2)}:d=#{td}[out]"
    else
      # Chain xfade between consecutive scaled streams
      # xfade offset = when the transition starts (relative to start of the chain)
      # After each xfade the effective duration shrinks by td (overlap)
      prev_label = "v0"
      accumulated_offset = 0.0

      (1...n).each do |i|
        accumulated_offset += duration_per_image - td
        out_label = (i == n - 1) ? "out" : "xf#{i}"
        filter_lines << "[#{prev_label}][v#{i}]xfade=transition=#{transition}:" \
                        "duration=#{td}:offset=#{accumulated_offset.round(3)}[#{out_label}]"
        prev_label = out_label
      end
    end

    filter_complex = filter_lines.join(";")

    # All inputs must come before output options
    audio_input = @audio_path ? ["-i", @audio_path] : []
    audio_index = @image_paths.size  # audio is the Nth input (0-based after images)

    cmd = ["ffmpeg", "-y"] +
      input_args +
      audio_input +
      ["-filter_complex", filter_complex,
       "-map", "[out]"]

    if @audio_path
      cmd += ["-map", "#{audio_index}:a",
              "-c:a", "aac", "-b:a", "192k",
              "-shortest"]
    end

    cmd += ["-c:v", "libx264", "-preset", "fast", "-crf", "23",
            "-pix_fmt", "yuv420p",
            "-movflags", "+faststart",
            "-t", @clip.duration.to_s,
            @output_path]

    run_ffmpeg(cmd)
    raise "FFmpeg failed: output missing or empty" unless File.exist?(@output_path) && File.size(@output_path) > 0
  end

  # Runs FFmpeg and updates generation_progress (20→95) by parsing
  # the structured progress lines FFmpeg sends to stdout via -progress pipe:1.
  def run_ffmpeg(cmd)
    require "open3"

    # Inject -progress pipe:1 just before the output path (last element)
    cmd_with_progress = cmd[0..-2] + ["-progress", "pipe:1", cmd.last]
    total_ms = @clip.duration * 1_000_000  # microseconds

    exit_status = nil
    Open3.popen3(*cmd_with_progress) do |_stdin, stdout, _stderr, wait_thr|
      stdout.each_line do |line|
        next unless line.start_with?("out_time_us=")
        out_us = line.split("=").last.strip.to_i
        next if out_us <= 0 || total_ms <= 0
        pct = (20 + (out_us.to_f / total_ms * 75)).clamp(20, 95).round
        @clip.update_column(:generation_progress, pct)
      end
      exit_status = wait_thr.value
    end

    raise "FFmpeg failed (exit #{exit_status&.exitstatus})" unless exit_status&.success?
  end

  def attach_video
    @clip.video.attach(
      io: File.open(@output_path),
      filename: "clip_#{@clip.id}.mp4",
      content_type: "video/mp4"
    )
  end

  def cleanup
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end
end
