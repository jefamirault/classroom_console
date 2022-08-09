class DiagnosticController < ApplicationController

  before_action :authenticate_user!, if: -> { !demo_mode? }

  # include ExportHelper
  def index
    # @assignments = read_json 'game_design_assignments.json'
    # respond_to do |format|
    #   format.html
    #   format.rss { render :layout => false }
    # end
  end

  def user
    respond_to do |format|
      format.js
    end
  end
  def course
    respond_to do |format|
      format.js
    end

  end
  def section
    respond_to do |format|
      format.js
    end

  end
  def enrollment
    respond_to do |format|
      format.js
    end

  end
  def grade
    respond_to do |format|
      format.js
    end

  end
  def term
    respond_to do |format|
      format.js
    end

  end
  def assignment
    respond_to do |format|
      format.js
    end

  end
end