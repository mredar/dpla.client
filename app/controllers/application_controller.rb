class ApplicationController < ActionController::Base
  skip_before_filter :verify_authenticity_token
  before_filter :authenticate_user!
  before_filter :authorize_user

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :exception

  # This is an api
  protect_from_forgery with: :exception

  def authorize_user
    if (!current_user.nil?)
      if current_user.authorization_level != 1
        render :status => :forbidden, :text => "It is Forbidden!"
      end
    end
  end
end
