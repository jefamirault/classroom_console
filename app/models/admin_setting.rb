
include OnApiHelper

class AdminSetting < ApplicationRecord

  # Canvas API path derived from Canvas path
  def canvas_api_path
    "#{canvas_path}/api/v1"
  end

  def self.canvas_api_test
    canvas_api_get('accounts')['status'] == '200 OK'
  end

  def self.on_api_test
    on_authenticate.code == '200'
  end

end

