
include OnApiHelper
include OneRosterApiHelper

class AdminSetting < ApplicationRecord

  # Canvas API path derived from Canvas path
  def canvas_api_path
    "#{canvas_path}/api/v1"
  end

  def self.canvas_api_test
    canvas_api_get('accounts')
  end

  def self.on_api_test
    on_authenticate
  end

  def self.oneroster_api_test
    oneroster_authenticate
  end

end

