require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Tiktok < OmniAuth::Strategies::OAuth2
      option :name, "tiktok"

      option :client_options, {
        site: "https://open.tiktokapis.com",
        authorize_url: "https://www.tiktok.com/v2/auth/authorize/",
        token_url: "https://open.tiktokapis.com/v2/oauth/token/"
      }

      option :scope, "user.info.basic,video.upload,video.publish"
      option :pkce, true

      uid { raw_info["open_id"] }

      info do
        {
          nickname: raw_info["display_name"],
          name:     raw_info["display_name"],
          image:    raw_info["avatar_url"]
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def authorize_params
        super.tap do |params|
          params[:client_key] = options.client_id
          params.delete(:client_id)
        end
      end

      def token_params
        super.tap do |params|
          params[:client_key]    = options.client_id
          params[:client_secret] = options.client_secret
          params.delete(:client_id)
        end
      end

      def raw_info
        @raw_info ||= begin
          response = access_token.get(
            "/v2/user/info/",
            params: { fields: "open_id,display_name,avatar_url" },
            headers: { "Authorization" => "Bearer #{access_token.token}" }
          )
          JSON.parse(response.body).dig("data", "user") || {}
        rescue StandardError
          {}
        end
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
