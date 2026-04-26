class CanvasApiController < ApplicationController
  include CanvasApiHelper

  def index
  end

  def get_accounts
    @accounts = JSON.parse(canvas_api_get('accounts').body)
  end

  def get_courses
    account_id = AdminSetting.first.account_id
    @courses = JSON.parse(canvas_api_get("accounts/#{account_id}/courses").body)
  end

  def get_users
    account_id = AdminSetting.first.account_id
    @users = JSON.parse(canvas_api_get("accounts/#{account_id}/users").body)
  end

  def get_roles
    account_id = AdminSetting.first.account_id
    @roles = JSON.parse(canvas_api_get("accounts/#{account_id}/roles").body)
  end

  def get_terms
    account_id = AdminSetting.first.account_id
    response = JSON.parse(canvas_api_get("accounts/#{account_id}/terms").body)
    @terms = response['enrollment_terms']
  end
end
