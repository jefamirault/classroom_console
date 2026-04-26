include CanvasApiHelper

class UsersController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.all
  end

  def show
    enrollments = @user.enrollments.includes(section: :term)

    course_data = enrollments.group_by { |e| e.section.course_id }.map do |_course_id, course_enrollments|
      course = course_enrollments.first.section.course
      terms = course_enrollments.map { |e| e.section.term }.uniq.compact
      {
        course: course,
        terms: terms,
        sections: course_enrollments.map { |e| e.section },
        role: course_enrollments.first.role,
        active: terms.any?(&:current?),
        latest_start: terms.map(&:start).compact.max
      }
    end

    @active_courses = course_data.select { |d| d[:active] }.sort_by { |d| d[:course].to_s }
    @inactive_courses = course_data.reject { |d| d[:active] }.sort_by { |d| d[:course].to_s }
    @sync_profiles = @user.sync_profiles.includes(:school_year).order(school_year_id: :desc)
    enabled_subs = Subscription.where(sync_profile: @user.sync_profiles, enabled: true).includes(section: :course)
    @syncing_courses = enabled_subs.group_by { |sub| sub.section&.course }.filter_map do |course, subs|
      { course: course, section_count: subs.count } if course
    end.sort_by { |d| d[:course].to_s }
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        format.html { redirect_to @user, notice: 'User successfully created.' }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def sync_sis_users
    User.sync_sis_users
    redirect_to users_path
  end
  def sync_canvas_users
    User.sync_canvas_users
    redirect_to users_path
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :sis_id, :canvas_id, :email)
  end
end