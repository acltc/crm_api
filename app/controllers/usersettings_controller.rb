class UsersettingsController < ApplicationController

  def edit
    @user = current_user
  end

  def update
    @user = current_user
  end

end
