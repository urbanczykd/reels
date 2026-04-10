class TiktokUploadService
  TIKTOK_API_URL = "https://open.tiktokapis.com/v2"

  def initialize(social_account, clip)
    @account = social_account
    @clip = clip
    @token = social_account.access_token
  end

  def call
    # TikTok Content Posting API flow:
    # 1. Initialize upload
    # 2. Upload video chunks
    # 3. Create post
    upload_response = initialize_upload
    upload_url = upload_response.dig("data", "upload_url")
    publish_id = upload_response.dig("data", "publish_id")

    upload_video(upload_url)

    result = check_post_status(publish_id)
    { status: "success", publish_id: publish_id, platform: "tiktok" }
  rescue => e
    { status: "error", error: e.message, platform: "tiktok" }
  end

  private

  def initialize_upload
    caption = [@clip.ai_caption, @clip.ai_hashtags].compact.join(" ")

    conn = Faraday.new(url: TIKTOK_API_URL) do |f|
      f.request :json
    end

    video_blob = @clip.video.blob

    response = conn.post("/post/publish/video/init/") do |req|
      req.headers["Authorization"] = "Bearer #{@token}"
      req.headers["Content-Type"] = "application/json; charset=UTF-8"
      req.body = JSON.generate({
        post_info: {
          title: caption.truncate(2200),
          privacy_level: "PUBLIC_TO_EVERYONE",
          disable_duet: false,
          disable_comment: false,
          disable_stitch: false
        },
        source_info: {
          source: "FILE_UPLOAD",
          video_size: video_blob.byte_size,
          chunk_size: video_blob.byte_size,
          total_chunk_count: 1
        }
      })
    end

    JSON.parse(response.body)
  end

  def upload_video(upload_url)
    video_data = @clip.video.download

    conn = Faraday.new do |f|
      f.adapter Faraday.default_adapter
    end

    conn.put(upload_url) do |req|
      req.headers["Content-Type"] = "video/mp4"
      req.headers["Content-Range"] = "bytes 0-#{video_data.size - 1}/#{video_data.size}"
      req.body = video_data
    end
  end

  def check_post_status(publish_id)
    conn = Faraday.new(url: TIKTOK_API_URL) do |f|
      f.request :json
    end

    10.times do
      response = conn.post("/post/publish/status/fetch/") do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
        req.body = JSON.generate({ publish_id: publish_id })
      end
      data = JSON.parse(response.body)
      status = data.dig("data", "status")
      return data if status == "PUBLISH_COMPLETE"
      raise "TikTok upload failed" if status&.include?("FAILED")
      sleep 5
    end
    raise "TikTok upload timed out"
  end
end
