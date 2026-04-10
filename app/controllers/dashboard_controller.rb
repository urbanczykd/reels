class DashboardController < ApplicationController
  def index
    @clips = current_user.clips.recent.limit(10)
    @connected_accounts = current_user.social_accounts
  end
end
