class SchoolYearsController < ApplicationController
  before_action :set_school_year, only: %i[ show edit update destroy ]

  # GET /school_years or /school_years.json
  def index
    @school_years = SchoolYear.all
  end

  # GET /school_years/1 or /school_years/1.json
  def show
  end

  # GET /school_years/new
  def new
    @school_year = SchoolYear.new
  end

  # GET /school_years/1/edit
  def edit
  end

  # POST /school_years or /school_years.json
  def create
    @school_year = SchoolYear.new(school_year_params)

    respond_to do |format|
      if @school_year.save
        format.html { redirect_to school_year_url(@school_year), notice: "School year was successfully created." }
        format.json { render :show, status: :created, location: @school_year }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @school_year.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /school_years/1 or /school_years/1.json
  def update
    respond_to do |format|
      if @school_year.update(school_year_params)
        format.html { redirect_to school_year_url(@school_year), notice: "School year was successfully updated." }
        format.json { render :show, status: :ok, location: @school_year }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @school_year.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /school_years/1 or /school_years/1.json
  def destroy
    @school_year.destroy

    respond_to do |format|
      format.html { redirect_to school_years_url, notice: "School year was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def sync_school_years
    SchoolYear.sync_sis_school_years
    redirect_to school_years_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_school_year
      @school_year = SchoolYear.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def school_year_params
      params.require(:school_year).permit(:name, :start_date, :end_date)
    end
end
