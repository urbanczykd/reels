class UploadToSocialJob < ApplicationJob
  queue_as :default

  SERVICE_MAP = {
    "instagram" => InstagramUploadService,
    "tiktok"    => TiktokUploadService,
    "youtube"   => YoutubeUploadService
  }.freeze

  def perform(clip_id, platform, social_account_id)
    clip = Clip.find(clip_id)
    social_account = SocialAccount.find(social_account_id)

    service_class = SERVICE_MAP[platform]
    raise "Unknown platform: #{platform}" unless service_class

    result = service_class.new(social_account, clip).call

    upload_results = clip.upload_results.merge(platform => result)
    clip.update!(upload_results: upload_results)
  rescue => e
    Rails.logger.error("UploadToSocialJob failed: #{e.message}")
    upload_results = clip.upload_results.merge(platform => { status: "error", error: e.message })
    clip.update!(upload_results: upload_results)
  end
end
