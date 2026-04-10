class SocialAccount < ApplicationRecord
  belongs_to :user

  PROVIDERS = %w[google_oauth2 facebook tiktok].freeze

  validates :provider, inclusion: { in: PROVIDERS }
  validates :uid, uniqueness: { scope: :provider }

  def provider_display_name
    case provider
    when "google_oauth2" then "YouTube"
    when "facebook" then "Instagram"
    when "tiktok" then "TikTok"
    else provider.humanize
    end
  end

  def provider_icon
    case provider
    when "google_oauth2" then "youtube"
    when "facebook" then "instagram"
    when "tiktok" then "tiktok"
    end
  end

  def token_valid?
    return true if token_expires_at.nil?
    token_expires_at > Time.current
  end
end
