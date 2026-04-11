class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: %i[google_oauth2 facebook tiktok]

  has_many :social_accounts, dependent: :destroy
  has_many :clips, dependent: :destroy
  has_many :soundtracks, dependent: :destroy

  scope :admins, -> { where(admin: true) }

  def social_account_for(provider)
    social_accounts.find_by(provider: provider.to_s)
  end

  def connected_to?(provider)
    social_account_for(provider).present?
  end
end
