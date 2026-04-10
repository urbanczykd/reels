# ReelMaker

Create short video reels from your photos and publish them to Instagram, TikTok, and YouTube — powered by FFmpeg + Ollama AI.

## Features
- Upload 2–20 images → generate a 5–10s reel (9:16 format, 1080×1920)
- Transition effects: Fade, Zoom, Slide, Dissolve
- AI caption & hashtag generation via Ollama (llama3.2, fully offline)
- One-click publish to Instagram Reels, TikTok, YouTube Shorts
- Background processing with Sidekiq

## Setup

### Prerequisites
- Ruby 3.3+
- PostgreSQL
- Redis
- FFmpeg (`brew install ffmpeg`)
- Ollama (`brew install ollama && ollama pull llama3.2`)

### Installation
```bash
git clone <repo>
cd reelmaker
cp .env.example .env  # Fill in your OAuth credentials
bundle install
rails db:create db:migrate
rails server
# In another terminal:
bundle exec sidekiq
```

### Docker
```bash
docker compose up -d
```

## OAuth Setup

### YouTube (Google)
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project → Enable "YouTube Data API v3"
3. Create OAuth 2.0 credentials
4. Add redirect URI: `http://localhost:3000/users/auth/google_oauth2/callback`

### Instagram (Facebook)
1. Go to [Meta Developers](https://developers.facebook.com)
2. Create app → Add Instagram Graph API
3. Request permissions: `instagram_basic`, `instagram_content_publish`
4. Requires a Business or Creator Instagram account linked to a Facebook Page

### TikTok
1. Go to [TikTok for Developers](https://developers.tiktok.com)
2. Create app → Request Content Posting API
3. Add redirect URI: `http://localhost:3000/users/auth/tiktok/callback`



 Key Features

  - Image upload — 2–20 images, draggable preview, ordered numbering                                                                                                         
  - Video generation — 1080×1920 MP4 (9:16 reel format), 4 transition effects (fade/zoom/slide/dissolve), 5–10s duration
  - AI captions — Ollama llama3.2 generates caption + hashtags offline via JSON mode                                                                                         
  - Social publishing — Instagram Reels (Graph API), TikTok (Content Posting API), YouTube Shorts (Data API v3 resumable upload)                                             
  - Background jobs — video generation and uploads run in Sidekiq, page auto-refreshes while processing                                                                      
                                                                                                                                                                             
  Quick Start                                                                                                                                                                
                                                                                                                                                                             
  cd reelmaker                                              
  cp .env.example .env      # fill in OAuth keys                                                                                                                             
  bundle install
  brew install ffmpeg                                                                                                                                                        
  ollama pull llama3.2       # one-time model download      
  rails db:create db:migrate                                                                                                                                                 
  rails server               # terminal 1
  bundle exec sidekiq        # terminal 2                                                                                                                                    
                                                            
  Or with Docker:                                                                                                                                                            
  docker compose up -d
                                                                                                                                                                             
  OAuth Keys Needed                                         

  1. YouTube — https://console.cloud.google.com → enable YouTube Data API v3 → OAuth credentials                                                                             
  2. Instagram — https://developers.facebook.com → requires a Business/Creator Instagram account linked to a Facebook Page
  3. TikTok — https://developers.tiktok.com → request Content Posting API access                                        