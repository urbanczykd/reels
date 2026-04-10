require Rails.root.join("lib/omniauth/strategies/tiktok")
require "devise/orm/active_record"

Devise.setup do |config|
  config.mailer_sender = ENV.fetch("MAILER_FROM", "no-reply@reelmaker.app")
  config.authentication_keys = [:email]
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  config.omniauth :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", ""),
    ENV.fetch("GOOGLE_CLIENT_SECRET", ""),
    scope: "email,profile,https://www.googleapis.com/auth/youtube.upload",
    access_type: "offline"

  config.omniauth :facebook,
    ENV.fetch("FACEBOOK_APP_ID", ""),
    ENV.fetch("FACEBOOK_APP_SECRET", ""),
    scope: "email,instagram_basic,instagram_content_publish,pages_read_engagement,pages_manage_posts",
    info_fields: "email,name"

  config.omniauth :tiktok,
    ENV.fetch("TIKTOK_CLIENT_KEY", ""),
    ENV.fetch("TIKTOK_CLIENT_SECRET", ""),
    scope: "user.info.basic,video.upload,video.publish"
end
