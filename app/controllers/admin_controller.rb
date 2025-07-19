class AdminController < ApplicationController
  def index
    @admin_settings = AdminSetting.first_or_create
  end

  def update
    @admin_settings = AdminSetting.first_or_create
    @admin_settings.update(admin_params)
    redirect_to admin_path
  end

  def test_canvas_api
    @result = AdminSetting.canvas_api_test ? "Success!" : "Failure."
    redirect_to admin_path(message: "Canvas API test: #{@result}")
  end
  def test_on_api
    @result = AdminSetting.on_api_test ? "Success!" : "Failure."
    respond_to do |format|
      format.js
    end
  end

  private

  def admin_params
    params.require(:admin_setting).permit(:canvas_path, :canvas_access_token, :on_api_path, :on_api_username, :on_api_key, :on_api_secret, :account_id,
                                          :sis_school_year, :sis_level_num, :sis_email_list_id, :sis_teacher_enrollments_list_id,
                                          :allow_on_api_read, :allow_on_api_write, :allow_canvas_api_read, :allow_canvas_api_write)
  end
end
