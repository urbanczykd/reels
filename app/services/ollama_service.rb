class OllamaService
  OLLAMA_URL = ENV.fetch("OLLAMA_URL", "http://localhost:11434")
  MODEL = ENV.fetch("OLLAMA_MODEL", "llama3.2")

  def self.generate_caption_and_hashtags(title, description = nil)
    new.generate_caption_and_hashtags(title, description)
  end

  def generate_caption_and_hashtags(title, description = nil)
    prompt = build_prompt(title, description)
    response = call_ollama(prompt)
    parse_response(response)
  rescue => e
    Rails.logger.error("Ollama error: #{e.message}")
    { caption: title, hashtags: "#reel #viral #fyp" }
  end

  private

  def build_prompt(title, description)
    <<~PROMPT
      You are a social media expert creating content for Instagram Reels, TikTok, and YouTube Shorts.

      Create an engaging caption and relevant hashtags for a short video reel with:
      Title: #{title}
      #{description.present? ? "Description: #{description}" : ""}

      Respond ONLY in this exact JSON format:
      {
        "caption": "engaging caption here (max 150 chars)",
        "hashtags": "#hashtag1 #hashtag2 #hashtag3 #hashtag4 #hashtag5 #hashtag6 #hashtag7 #hashtag8 #hashtag9 #hashtag10"
      }

      Make the caption engaging, trendy, and include a call to action. Include mix of popular and niche hashtags.
    PROMPT
  end

  def call_ollama(prompt)
    conn = Faraday.new(url: OLLAMA_URL) do |f|
      f.options.timeout = 60
    end

    response = conn.post("/api/generate") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate({
        model: MODEL,
        prompt: prompt,
        stream: false,
        format: "json"
      })
    end

    JSON.parse(response.body)["response"]
  end

  def parse_response(response)
    data = JSON.parse(response)
    {
      caption: data["caption"].to_s.truncate(150),
      hashtags: data["hashtags"].to_s
    }
  rescue JSON::ParserError
    { caption: response.to_s.truncate(150), hashtags: "#reel #viral #fyp" }
  end
end
