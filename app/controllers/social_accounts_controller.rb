class SocialAccountsController < ApplicationController
  def index
    @social_accounts = current_user.social_accounts
  end

  def destroy
    account = current_user.social_accounts.find(params[:id])
    account.destroy
    redirect_to social_accounts_path, notice: "#{account.provider_display_name} disconnected."
  end
end
