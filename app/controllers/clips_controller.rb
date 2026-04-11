class ClipsController < ApplicationController
  before_action :set_clip, only: [:show, :destroy, :generate, :upload_to_social, :stream_video, :progress]

  def index
    @clips = current_user.clips.recent
  end

  def new
    @clip = current_user.clips.new
    @soundtracks = Soundtrack.for_user(current_user)
  end

  def create
    @clip = current_user.clips.new(clip_params)

    if @clip.save
      GenerateClipJob.perform_later(@clip.id)
      redirect_to @clip, notice: "Clip created! AI is generating your video..."
    else
      @soundtracks = Soundtrack.for_user(current_user)
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def destroy
    @clip.destroy
    redirect_to clips_path, notice: "Clip deleted."
  end

  def generate
    GenerateClipJob.perform_later(@clip.id)
    @clip.mark_processing!
    redirect_to @clip, notice: "Re-generating video..."
  end

  def upload_to_social
    platform = params[:platform]
    unless %w[instagram tiktok youtube].include?(platform)
      return redirect_to @clip, alert: "Invalid platform."
    end

    social_account = current_user.social_account_for(provider_for(platform))
    unless social_account
      return redirect_to @clip, alert: "Please connect your #{platform.humanize} account first."
    end

    unless @clip.ready? && @clip.video.attached?
      return redirect_to @clip, alert: "Video is not ready yet."
    end

    UploadToSocialJob.perform_later(@clip.id, platform, social_account.id)
    redirect_to @clip, notice: "Uploading to #{platform.humanize}..."
  end

  def progress
    render json: {
      status:   @clip.status,
      progress: @clip.generation_progress,
      message:  progress_message(@clip)
    }
  end

  def stream_video
    if @clip.video.attached?
      redirect_to url_for(@clip.video)
    else
      head :not_found
    end
  end

  private

  def set_clip
    @clip = current_user.clips.find(params[:id])
  end

  def clip_params
    params.require(:clip).permit(:title, :description, :duration, :transition_effect, :soundtrack_id, images: [])
  end

  def progress_message(clip)
    return "Failed: #{clip.error_message&.truncate(80)}" if clip.failed?
    return "Ready!" if clip.ready?
    case clip.generation_progress
    when 0..4  then "Queued..."
    when 5..19 then "Starting job..."
    when 20..29 then "Generating AI caption..."
    when 30..89 then "Rendering video with FFmpeg..."
    when 90..99 then "Finalising..."
    else "Done!"
    end
  end

  def provider_for(platform)
    { "instagram" => "facebook", "youtube" => "google_oauth2", "tiktok" => "tiktok" }[platform]
  end
end
