class ApplicationController < ActionController::Base

  before_action :authenticate_user!, if: -> { !demo_mode? }

  private

  def demo_mode?
    ENV['DEMO'] == 'true'
  end
end
