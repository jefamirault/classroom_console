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
    render_api_test_result("Canvas API") { AdminSetting.canvas_api_test }
  end

  def test_on_api
    render_api_test_result("ON API") { AdminSetting.on_api_test }
  end

  def test_oneroster_api
    render_api_test_result("OneRoster API") { AdminSetting.oneroster_api_test }
  end

  private

  def render_api_test_result(api_name)
    @api_name = api_name
    begin
      @response = yield
    rescue StandardError => e
      @error = e
    end
    render :test_api_result
  end

  def admin_params
    params.require(:admin_setting).permit(:canvas_path, :canvas_access_token, :on_api_path, :on_api_username, :on_api_key,
                                          :on_api_secret, :account_id, :sis_school_year, :sis_level_num,
                                          :allow_on_api_read, :allow_on_api_write, :allow_canvas_api_read, :allow_canvas_api_write,
                                          :oneroster_api_path, :oneroster_key, :oneroster_secret, :oneroster_scope)
  end
end
