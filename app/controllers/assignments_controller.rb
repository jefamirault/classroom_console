class AssignmentsController < ApplicationController
  include ExportHelper
  def index
    @assignments = read_json 'game_design_assignments.json'
    respond_to do |format|
      format.html
      format.rss { render :layout => false }
    end
  end
end