class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    handle_auth("YouTube")
  end

  def facebook
    handle_auth("Instagram")
  end

  def tiktok
    handle_auth("TikTok")
  end

  def failure
    redirect_to root_path, alert: "Authentication failed: #{failure_message}"
  end

  private

  def handle_auth(platform_name)
    auth = request.env["omniauth.auth"]

    social_account = current_user.social_accounts.find_or_initialize_by(
      provider: auth.provider,
      uid: auth.uid
    )

    social_account.update!(
      username: auth.info.name || auth.info.nickname,
      access_token: auth.credentials.token,
      refresh_token: auth.credentials.refresh_token,
      token_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
      extra_data: auth.extra&.raw_info&.to_h || {}
    )

    redirect_to social_accounts_path, notice: "#{platform_name} connected successfully!"
  rescue => e
    redirect_to social_accounts_path, alert: "Failed to connect #{platform_name}: #{e.message}"
  end
end
