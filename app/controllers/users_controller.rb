include CanvasApiHelper

class UsersController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.all
  end

  def show
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

  def sync_canvas_users
    User.sync_canvas_users
    redirect_to users_path
  end

  # def refresh_canvas_users
  #   User.refresh_canvas_users
  #   redirect_to users_path
  # end
  #
  # def create_missing_canvas_users
  #   User.create_missing_canvas_users
  #   redirect_to users_path
  # end

  def refresh_sis_emails
    User.refresh_sis_emails
    redirect_to users_path
  end

  def sync_sis_teacher_enrollments
    Enrollment.get_sis_teacher_enrollments
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