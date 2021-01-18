class TermsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_term, only: [:show, :edit, :update, :destroy]

  # GET /terms
  # GET /terms.json
  def index
    @terms = Term.all
  end

  # GET /terms/1
  # GET /terms/1.json
  def show
  end

  # GET /terms/new
  def new
    @term = Term.new
  end

  # GET /terms/1/edit
  def edit
  end

  # POST /terms
  # POST /terms.json
  def create
    @term = Term.new(term_params)

    respond_to do |format|
      if @term.save
        format.html { redirect_to @term, notice: 'Term was successfully created.' }
        format.json { render :show, status: :created, location: @term }
      else
        format.html { render :new }
        format.json { render json: @term.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /terms/1
  # PATCH/PUT /terms/1.json
  def update
    respond_to do |format|
      if @term.update(term_params)
        format.html { redirect_to @term, notice: 'Term was successfully updated.' }
        format.json { render :show, status: :ok, location: @term }
      else
        format.html { render :edit }
        format.json { render json: @term.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /terms/1
  # DELETE /terms/1.json
  def destroy
    @term.destroy
    respond_to do |format|
      format.html { redirect_to terms_url, notice: 'Term was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  include ExportHelper
  def detect
    sections = read_json 'sis_sections.json'
    courses = read_json 'sis_courses.json'

    terms = Term.get_sis_values sections, courses
    if Term.count == 0
      # TODO reconcile with Canvas terms
      # Term.upsert_all terms, unique_by: canvas_id
      Term.upsert_all terms
    end

    canvas_terms = read_json 'canvas_terms.json'
    Term.match_canvas_terms canvas_terms

    redirect_to terms_path
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_term
      @term = Term.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def term_params
      params.require(:term).permit(:name, :canvas_id, :start, :end)
    end
end
