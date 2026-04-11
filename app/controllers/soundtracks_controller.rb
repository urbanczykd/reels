class SoundtracksController < ApplicationController
  before_action :set_soundtrack, only: [:destroy]

  def index
    @soundtracks = Soundtrack.for_user(current_user)
  end

  def new
    @soundtrack = current_user.soundtracks.new
  end

  def create
    @soundtrack = current_user.soundtracks.new(soundtrack_params)

    if @soundtrack.save
      DetectAudioDurationJob.perform_later(@soundtrack.id)
      redirect_to soundtracks_path, notice: "Soundtrack \"#{@soundtrack.name}\" uploaded!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @soundtrack.global?
      redirect_to soundtracks_path, alert: "Default soundtracks cannot be deleted."
    else
      @soundtrack.destroy
      redirect_to soundtracks_path, notice: "Soundtrack deleted."
    end
  end

  private

  def set_soundtrack
    # Allow destroy only on user-owned or global (but we block global above)
    @soundtrack = Soundtrack.for_user(current_user).find(params[:id])
  end

  def soundtrack_params
    params.require(:soundtrack).permit(:name, :description, :audio_file)
  end
end
