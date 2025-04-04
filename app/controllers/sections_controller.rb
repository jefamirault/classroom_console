class SectionsController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }
  before_action :set_section, only: [:show, :edit, :update, :destroy, :sync_sis_assignments, :clear_sis_assignments]

  # GET /sections
  # GET /sections.json
  def index
    @sections = Section.includes(:course).all.order(canvas_id: :desc, name: :asc)
    @full_count = @sections.size
    # @sections = @sections.first(50) unless params[:all]
  end

  # GET /sections/1
  # GET /sections/1.json
  def show

  end

  # GET /sections/new
  def new
    @section = Section.new
  end

  # GET /sections/1/edit
  def edit
  end

  # POST /sections
  # POST /sections.json
  def create
    @section = Section.new(section_params)

    respond_to do |format|
      if @section.save
        format.html { redirect_to @section, notice: 'Section was successfully created.' }
        format.json { render :show, status: :created, location: @section }
      else
        format.html { render :new }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sections/1
  # PATCH/PUT /sections/1.json
  def update
    respond_to do |format|
      if @section.update(section_params)
        format.html { redirect_to @section, notice: 'Section was successfully updated.' }
        format.json { render :show, status: :ok, location: @section }
      else
        format.html { render :edit }
        format.json { render json: @section.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sections/1
  # DELETE /sections/1.json
  def destroy
    @section.destroy
    respond_to do |format|
      format.html { redirect_to sections_url, notice: 'Section was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def sync
    @section = Section.find params[:section_id]
    @section.sync
    redirect_to @section
  end

  def sync_sis_assignments
    @section.sync_sis_assignments
    redirect_to @section
  end

  def clear_sis_assignments
    @section.assignment = nil
    @section.save
    redirect_to @section
  end
  def sync_all_sis_assignments
    Section.sync_all_sis_assignments
    redirect_to sections_path
  end

  def sync_all_canvas_sections
    Course.where(sync_course: true).each &:sync_canvas_sections
    redirect_to sections_path
  end

  def enroll_users_in_canvas
    @section = Section.find params[:section_id]
    @section.enroll_users_in_canvas
    redirect_to @section
  end

  def create_canvas_course
    @section = Section.find params[:section_id]
    @section.course.create_canvas_course(@section.term)
    redirect_to @section
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section
      @section = Section.includes(:users).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def section_params
      params.require(:section).permit(:name, :sis_id, :course_id, :canvas_id, :canvas_course_id, :term_id)
    end
end
