class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :social_accounts, dependent: :destroy
  has_many :clips, dependent: :destroy

  def social_account_for(provider)
    social_accounts.find_by(provider: provider.to_s)
  end

  def connected_to?(provider)
    social_account_for(provider).present?
  end
end
