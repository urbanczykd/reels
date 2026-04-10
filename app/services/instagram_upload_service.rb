class InstagramUploadService
  GRAPH_API_URL = "https://graph.facebook.com/v19.0"

  def initialize(social_account, clip)
    @account = social_account
    @clip = clip
    @token = social_account.access_token
  end

  def call
    # Instagram Reels upload requires:
    # 1. Get Instagram Business Account ID
    # 2. Create media container with video URL
    # 3. Wait for processing
    # 4. Publish container

    ig_user_id = get_instagram_user_id
    raise "No Instagram Business/Creator account found" unless ig_user_id

    video_url = generate_public_url
    container_id = create_media_container(ig_user_id, video_url)

    wait_for_processing(ig_user_id, container_id)

    media_id = publish_container(ig_user_id, container_id)
    { status: "success", media_id: media_id, platform: "instagram" }
  rescue => e
    { status: "error", error: e.message, platform: "instagram" }
  end

  private

  def get_instagram_user_id
    conn = Faraday.new(url: GRAPH_API_URL)
    response = conn.get("/me/accounts", { access_token: @token, fields: "instagram_business_account" })
    data = JSON.parse(response.body)
    data.dig("data", 0, "instagram_business_account", "id")
  end

  def generate_public_url
    # In production, use your app's public URL or CDN
    # For development, you'd need ngrok or similar
    Rails.application.routes.url_helpers.url_for(
      controller: "clips",
      action: "stream_video",
      id: @clip.id,
      host: ENV.fetch("APP_HOST", "localhost:3000")
    )
  end

  def create_media_container(ig_user_id, video_url)
    caption = [@clip.ai_caption, @clip.ai_hashtags].compact.join("\n\n")
    conn = Faraday.new(url: GRAPH_API_URL)
    response = conn.post("/#{ig_user_id}/media") do |req|
      req.params = {
        video_url: video_url,
        caption: caption,
        media_type: "REELS",
        access_token: @token
      }
    end
    data = JSON.parse(response.body)
    raise data["error"]["message"] if data["error"]
    data["id"]
  end

  def wait_for_processing(ig_user_id, container_id, max_attempts: 20)
    max_attempts.times do
      conn = Faraday.new(url: GRAPH_API_URL)
      response = conn.get("/#{container_id}", {
        fields: "status_code,status",
        access_token: @token
      })
      data = JSON.parse(response.body)
      status = data["status_code"]
      return if status == "FINISHED"
      raise "Upload failed: #{data['status']}" if status == "ERROR"
      sleep 3
    end
    raise "Upload timed out"
  end

  def publish_container(ig_user_id, container_id)
    conn = Faraday.new(url: GRAPH_API_URL)
    response = conn.post("/#{ig_user_id}/media_publish") do |req|
      req.params = {
        creation_id: container_id,
        access_token: @token
      }
    end
    data = JSON.parse(response.body)
    raise data["error"]["message"] if data["error"]
    data["id"]
  end
end
