require "streamio-ffmpeg"

class VideoGeneratorService
  REEL_WIDTH  = 1080
  REEL_HEIGHT = 1920
  FPS = 30

  TRANSITIONS = {
    "fade"    => "fade=t=in:st=0:d=0.5,fade=t=out:st=%<out_start>s:d=0.5",
    "slide"   => "zoompan=z='1':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=%<frames>s:fps=#{FPS}",
    "zoom"    => "zoompan=z='min(zoom+0.0015,1.5)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=%<frames>s:fps=#{FPS}",
    "dissolve" => "fade=t=in:st=0:d=0.3,fade=t=out:st=%<out_start>s:d=0.3"
  }.freeze

  def initialize(clip)
    @clip = clip
  end

  def call
    prepare_temp_dir
    download_images
    generate_video
    attach_video
  ensure
    cleanup
  end

  private

  def prepare_temp_dir
    @temp_dir = Rails.root.join("tmp", "clip_#{@clip.id}_#{Time.now.to_i}")
    FileUtils.mkdir_p(@temp_dir)
    @output_path = File.join(@temp_dir, "output.mp4")
  end

  def download_images
    @image_paths = []
    @clip.images.each_with_index do |img, i|
      path = File.join(@temp_dir, "image_#{i.to_s.rjust(3, '0')}.jpg")
      File.open(path, "wb") { |f| f.write(img.download) }
      @image_paths << path
    end
  end

  def generate_video
    duration_per_image = @clip.duration.to_f / @image_paths.size
    frames_per_image = (duration_per_image * FPS).round

    # Build concat input list
    list_path = File.join(@temp_dir, "input.txt")
    File.open(list_path, "w") do |f|
      @image_paths.each do |img|
        f.puts "file '#{img}'"
        f.puts "duration #{duration_per_image.round(3)}"
      end
      # Repeat last image to avoid ffmpeg concat issue
      f.puts "file '#{@image_paths.last}'"
    end

    # Scale + pad to 9:16 reel format with zoom effect
    vf_filter = build_video_filter(duration_per_image, frames_per_image)

    ffmpeg_cmd = [
      "ffmpeg", "-y",
      "-f", "concat", "-safe", "0", "-i", list_path,
      "-vf", vf_filter,
      "-c:v", "libx264", "-preset", "fast", "-crf", "23",
      "-r", FPS.to_s,
      "-pix_fmt", "yuv420p",
      "-movflags", "+faststart",
      "-t", @clip.duration.to_s,
      @output_path
    ]

    result = system(*ffmpeg_cmd)
    raise "FFmpeg failed" unless result && File.exist?(@output_path)
  end

  def build_video_filter(duration_per_image, frames_per_image)
    out_start = [duration_per_image - 0.5, 0].max
    effect = @clip.transition_effect

    zoom_filter = case effect
    when "zoom"
      "zoompan=z='min(zoom+0.0015,1.5)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=#{frames_per_image}:fps=#{FPS}:s=#{REEL_WIDTH}x#{REEL_HEIGHT}"
    when "slide"
      "zoompan=z='1.0':x='if(gte(on,1),x+2,0)':y='ih/2-(ih/zoom/2)':d=#{frames_per_image}:fps=#{FPS}:s=#{REEL_WIDTH}x#{REEL_HEIGHT}"
    else
      "scale=#{REEL_WIDTH}:#{REEL_HEIGHT}:force_original_aspect_ratio=decrease,pad=#{REEL_WIDTH}:#{REEL_HEIGHT}:(ow-iw)/2:(oh-ih)/2:black"
    end

    fade = "fade=t=in:st=0:d=0.4,fade=t=out:st=#{out_start.round(2)}:d=0.4"
    "#{zoom_filter},#{fade}"
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
