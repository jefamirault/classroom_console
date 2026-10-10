class ApplicationController < ActionController::Base
  include Masquerading

  before_action :authenticate_user!, if: -> { !demo_mode? }

  private

  def demo_mode?
    ENV['DEMO'] == 'true'
  end
end
