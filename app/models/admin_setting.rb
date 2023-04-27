
include OnApiHelper

class AdminSetting < ApplicationRecord

  # Canvas API path derived from Canvas path
  def canvas_api_path
    "#{canvas_path}/api/v1"
  end
  def self.canvas_path
    AdminSetting.first_or_create.canvas_path
  end
  def self.canvas_api_path
    AdminSetting.first_or_create.canvas_api_path
  end
  def self.canvas_access_token
    AdminSetting.first_or_create.canvas_access_token
  end
  def self.on_api_path
    AdminSetting.first_or_create.on_api_path
  end
  def self.on_api_username
    AdminSetting.first_or_create.on_api_username
  end
  def self.on_api_key
    AdminSetting.first_or_create.on_api_key
  end
  def self.on_api_secret
    AdminSetting.first_or_create.on_api_secret
  end
  def self.account_id
    AdminSetting.first_or_create.account_id
  end
  def self.sis_school_year
    AdminSetting.first_or_create.sis_school_year
  end
  def self.sis_level_num
    AdminSetting.first_or_create.sis_level_num
  end
  def self.sis_email_list_id
    AdminSetting.first_or_create.sis_email_list_id
  end
  def self.sis_teacher_enrollments_list_id
    AdminSetting.first_or_create.sis_teacher_enrollments_list_id
  end

  def self.canvas_api_test
    canvas_api_get('accounts')['status'] == '200 OK'
  end

  def self.on_api_test
    on_authenticate.code == '200'
  end

end

