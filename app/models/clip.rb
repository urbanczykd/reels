class Clip < ApplicationRecord
  belongs_to :user

  has_many_attached :images
  has_one_attached :video

  STATUSES = %w[pending processing ready failed uploading].freeze
  TRANSITIONS = %w[fade slide zoom dissolve].freeze
  MAX_IMAGES = 20
  MIN_IMAGES = 2

  validates :title, presence: true
  validates :duration, inclusion: { in: 5..10 }
  validates :transition_effect, inclusion: { in: TRANSITIONS }
  validates :status, inclusion: { in: STATUSES }
  validate :image_count_valid

  scope :recent, -> { order(created_at: :desc) }

  def pending?   = status == "pending"
  def processing? = status == "processing"
  def ready?     = status == "ready"
  def failed?    = status == "failed"

  def mark_processing! = update!(status: "processing", error_message: nil)
  def mark_ready!      = update!(status: "ready")
  def mark_failed!(msg) = update!(status: "failed", error_message: msg)

  def uploaded_to?(platform)
    upload_results[platform.to_s]&.dig("status") == "success"
  end

  private

  def image_count_valid
    count = images.attachments.size
    if count < MIN_IMAGES
      errors.add(:images, "must have at least #{MIN_IMAGES} images")
    elsif count > MAX_IMAGES
      errors.add(:images, "cannot have more than #{MAX_IMAGES} images")
    end
  end
end
