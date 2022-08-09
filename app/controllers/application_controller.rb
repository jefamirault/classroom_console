class ApplicationController < ActionController::Base

  private

  def demo_mode?
    ENV['DEMO'] == 'true'
  end
end
