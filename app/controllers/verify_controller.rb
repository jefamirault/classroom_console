class VerifyController < ApplicationController
  def index
    redirect_to courses_path unless demo_mode?
  end
end
