class Soundtrack < ApplicationRecord
  belongs_to :user, optional: true
  has_one_attached :audio_file
  has_many :clips, dependent: :nullify

  validates :name, presence: true
  validates :audio_file, attached: true,
    content_type: { in: %w[audio/mpeg audio/mp4 audio/ogg audio/x-wav audio/vnd.wave audio/flac audio/x-flac audio/aac audio/x-aiff], message: "must be an audio file" }

  scope :recent,  -> { order(created_at: :desc) }
  scope :global,  -> { where(global: true) }
  scope :for_user, ->(user) { where(user: user).or(where(global: true)).order(global: :desc, created_at: :desc) }

  def duration_label
    return nil unless duration_seconds
    min = duration_seconds / 60
    sec = duration_seconds % 60
    format("%d:%02d", min, sec)
  end
end
