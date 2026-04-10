class YoutubeUploadService
  YOUTUBE_API_URL = "https://www.googleapis.com/upload/youtube/v3"
  YOUTUBE_BASE_URL = "https://www.googleapis.com/youtube/v3"

  def initialize(social_account, clip)
    @account = social_account
    @clip = clip
    @token = social_account.access_token
  end

  def call
    # YouTube Data API v3 - Resumable upload for Shorts
    upload_url = initiate_resumable_upload
    video_id = upload_video(upload_url)

    { status: "success", video_id: video_id, platform: "youtube",
      url: "https://youtube.com/shorts/#{video_id}" }
  rescue => e
    { status: "error", error: e.message, platform: "youtube" }
  end

  private

  def initiate_resumable_upload
    description = [@clip.description, @clip.ai_caption, @clip.ai_hashtags].compact.join("\n\n")

    conn = Faraday.new(url: YOUTUBE_API_URL)
    response = conn.post("/video") do |req|
      req.params = {
        uploadType: "resumable",
        part: "snippet,status"
      }
      req.headers["Authorization"] = "Bearer #{@token}"
      req.headers["Content-Type"] = "application/json"
      req.headers["X-Upload-Content-Type"] = "video/mp4"
      req.headers["X-Upload-Content-Length"] = @clip.video.blob.byte_size.to_s
      req.body = JSON.generate({
        snippet: {
          title: @clip.title.truncate(100),
          description: description.truncate(5000),
          tags: extract_hashtag_words,
          categoryId: "22"  # People & Blogs
        },
        status: {
          privacyStatus: "public",
          selfDeclaredMadeForKids: false
        }
      })
    end

    raise "Failed to initiate upload: #{response.status}" unless response.headers["location"]
    response.headers["location"]
  end

  def upload_video(upload_url)
    video_data = @clip.video.download

    conn = Faraday.new
    response = conn.put(upload_url) do |req|
      req.headers["Authorization"] = "Bearer #{@token}"
      req.headers["Content-Type"] = "video/mp4"
      req.headers["Content-Length"] = video_data.size.to_s
      req.body = video_data
    end

    data = JSON.parse(response.body)
    raise "Upload failed: #{data.dig('error', 'message')}" if data["error"]
    data["id"]
  end

  def extract_hashtag_words
    return [] unless @clip.ai_hashtags.present?
    @clip.ai_hashtags.scan(/#(\w+)/).flatten.first(15)
  end
end
