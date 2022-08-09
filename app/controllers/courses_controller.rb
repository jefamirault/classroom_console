class CoursesController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }
  before_action :set_course, only: [:show, :edit, :update, :destroy]

  # GET /courses
  # GET /courses.json
  def index
    @courses = Course.where.not(sections_count: 0).order(sync_course: :desc)
    @full_count = @courses.size
    @courses = @courses.first(50) unless params[:all]
  end

  # GET /courses/1
  # GET /courses/1.json
  def show
  end

  # GET /courses/new
  def new
    @course = Course.new
  end

  # GET /courses/1/edit
  def edit
  end

  # POST /courses
  # POST /courses.json
  def create
    @course = Course.new(course_params)

    respond_to do |format|
      if @course.save
        format.html { redirect_to @course, notice: 'Course was successfully created.' }
        format.json { render :show, status: :created, location: @course }
      else
        format.html { render :new }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /courses/1
  # PATCH/PUT /courses/1.json
  def update
    respond_to do |format|
      if @course.update(course_params)
        format.html { redirect_to @course, notice: 'Course was successfully updated.' }
        format.json { render :show, status: :ok, location: @course }
      else
        format.html { render :edit }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /courses/1
  # DELETE /courses/1.json
  def destroy
    @course.destroy
    respond_to do |format|
      format.html { redirect_to courses_url, notice: 'Course was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def sync_sis_enrollments
    @course = Course.find params[:course_id]
    @course.sync_sis_enrollments
    redirect_to course_path(@course)
  end

  def sync_all_sis_enrollments
    Course.sync_all_sis_enrollments
    redirect_to courses_path
  end
  def create_canvas_sections
    @course = Course.find params[:course_id]
    @course.create_canvas_sections
    redirect_to course_path(@course)
  end
  def enroll_users_in_canvas
    @course = Course.find params[:course_id]
    @course.enroll_users_in_canvas
    redirect_to course_path(@course)
  end

  def create_canvas_courses
    Course.create_canvas_courses
    redirect_to courses_path
  end

  def generate_sample_data
    generate_sample if ENV['DEMO']
    redirect_to courses_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_course
      @course = Course.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def course_params
      params.require(:course).permit(:name, :sis_id, :is_active, :course_length, :sync_course, :sync_grades)
    end
end
