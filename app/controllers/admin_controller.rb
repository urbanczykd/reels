class AdminController < ApplicationController
  before_action :require_admin!
  before_action :set_clip, only: [:retry_clip, :stop_clip, :destroy_clip], unless: -> { params[:bulk] }

  def dashboard
    @stats = {
      users:            User.count,
      clips:            Clip.count,
      clips_by_status:  Clip.group(:status).count,
      soundtracks:      Soundtrack.count,
      ready_clips:      Clip.where(status: "ready").count,
      failed_clips:     Clip.where(status: "failed").count,
      processing_clips: Clip.where(status: "processing").count
    }
    @recent_clips      = Clip.includes(:user).order(created_at: :desc).limit(10)
    @processing_clips  = Clip.includes(:user).where(status: "processing").order(updated_at: :asc)
    @failed_clips      = Clip.includes(:user).where(status: "failed").order(updated_at: :desc)
  end

  def stop_clip
    if params[:bulk]
      clips = Clip.where(status: "processing")
      count = clips.count
      clips.update_all(status: "failed", error_message: "Stopped by admin")
      redirect_to admin_dashboard_path, notice: "#{count} processing clip#{"s" if count != 1} stopped."
    else
      @clip.mark_failed!("Stopped by admin")
      if params[:retry]
        @clip.update!(status: "pending", error_message: nil)
        GenerateClipJob.perform_later(@clip.id)
        redirect_to admin_dashboard_path, notice: "Clip \"#{@clip.title}\" stopped and re-queued."
      else
        redirect_to admin_dashboard_path, notice: "Clip \"#{@clip.title}\" stopped."
      end
    end
  end

  def retry_clip
    if params[:bulk]
      clips = Clip.where(status: "failed")
      clips.each do |clip|
        clip.update!(status: "pending", error_message: nil)
        GenerateClipJob.perform_later(clip.id)
      end
      redirect_to admin_dashboard_path, notice: "#{clips.size} clips re-queued."
    else
      @clip.update!(status: "pending", error_message: nil)
      GenerateClipJob.perform_later(@clip.id)
      redirect_to admin_dashboard_path, notice: "Clip \"#{@clip.title}\" re-queued."
    end
  end

  def destroy_clip
    title = @clip.title
    @clip.video.purge if @clip.video.attached?
    @clip.images.purge
    @clip.destroy
    redirect_to admin_dashboard_path, notice: "Clip \"#{title}\" deleted."
  end

  private

  def set_clip
    @clip = Clip.find(params[:id])
  end

  def require_admin!
    redirect_to root_path, alert: "Access denied." unless current_user&.admin?
  end
end
