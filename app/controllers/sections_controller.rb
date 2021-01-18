class SectionsController < ApplicationController

  before_action :authenticate_user!
  before_action :set_section, only: [:show, :edit, :update, :destroy]

  # GET /sections
  # GET /sections.json
  def index
    @sections = Section.includes(:course).all.order(sync_grades: :desc, name: :asc)
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

  def sync_all_grades
    Section.sync_all_grades
    redirect_to sections_path
  end

  def sync_all_sis_assignments
    Section.sync_all_sis_assignments
    redirect_to sections_path
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_section
      @section = Section.includes(:users).find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def section_params
      params.require(:section).permit(:name, :sis_id, :course_id, :canvas_id, :canvas_course_id, :term_id, :sync_grades)
    end
end
