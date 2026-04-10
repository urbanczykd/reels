class ClipsController < ApplicationController
  before_action :set_clip, only: [:show, :destroy, :generate, :upload_to_social, :stream_video]

  def index
    @clips = current_user.clips.recent
  end

  def new
    @clip = current_user.clips.new
  end

  def create
    @clip = current_user.clips.new(clip_params)

    if @clip.save
      GenerateClipJob.perform_later(@clip.id)
      redirect_to @clip, notice: "Clip created! AI is generating your video..."
    else
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
    params.require(:clip).permit(:title, :description, :duration, :transition_effect, images: [])
  end

  def provider_for(platform)
    { "instagram" => "facebook", "youtube" => "google_oauth2", "tiktok" => "tiktok" }[platform]
  end
end
