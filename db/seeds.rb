require "tempfile"
require "net/http"

# ---------------------------------------------------------------------------
# Global soundtracks — SoundHelix generated music (public domain, free to use).
# Replaces any previously seeded global tracks.
# ---------------------------------------------------------------------------

GLOBAL_SOUNDTRACKS = [
  {
    name: "Upbeat Energy",
    description: "High-energy electronic track — great for travel, sports, and lifestyle reels",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
    filename: "upbeat_energy.mp3",
    duration_seconds: 372
  },
  {
    name: "Chill Flow",
    description: "Relaxed instrumental groove — perfect for food, art, and aesthetic content",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
    filename: "chill_flow.mp3",
    duration_seconds: 426
  },
  {
    name: "Cinematic Drive",
    description: "Dramatic build-up — ideal for transformations, reveals, and epic moments",
    url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
    filename: "cinematic_drive.mp3",
    duration_seconds: 344
  }
].freeze

HEADERS = {
  "User-Agent" => "Mozilla/5.0 (compatible; ReelMaker/1.0)"
}.freeze

def download_mp3(url)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = uri.scheme == "https"
  http.open_timeout = 15
  http.read_timeout = 120

  request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
  response = http.request(request)

  5.times do
    break unless response.is_a?(Net::HTTPRedirection)
    uri = URI.parse(response["Location"])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    request = Net::HTTP::Get.new(uri.request_uri, HEADERS)
    response = http.request(request)
  end

  raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)
  response.body
end

puts "🗑  Removing old global soundtracks..."
Soundtrack.global.each { |s| s.audio_file.purge if s.audio_file.attached?; s.destroy }

puts "🎵 Seeding global soundtracks..."

GLOBAL_SOUNDTRACKS.each do |attrs|
  next if Soundtrack.global.exists?(name: attrs[:name])
  print "  Downloading #{attrs[:name]}... "

  begin
    data = download_mp3(attrs[:url])
    raise "too small" unless data.bytesize > 100_000

    Tempfile.create([File.basename(attrs[:filename], ".*"), ".mp3"]) do |tmp|
      tmp.binmode
      tmp.write(data)
      tmp.flush

      st = Soundtrack.new(
        name: attrs[:name],
        description: attrs[:description],
        duration_seconds: attrs[:duration_seconds],
        global: true,
        user: nil
      )
      st.audio_file.attach(io: File.open(tmp.path), filename: attrs[:filename], content_type: "audio/mpeg")
      st.save!
    end
    puts "✓ (#{(data.bytesize / 1024.0 / 1024.0).round(1)} MB)"
  rescue => e
    puts "✗ #{e.message}"
  end
end

puts "Done."

# Admin user
admin = User.find_or_initialize_by(email: "urbanczykd@gmail.com")
admin.name     = "Darek" if admin.name.blank?
admin.password = SecureRandom.hex(16) if admin.new_record?
admin.admin    = true
admin.save!
puts "👤 Admin: urbanczykd@gmail.com"
