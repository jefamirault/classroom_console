class GradesController < ApplicationController
  def index
    @grades = GradeChange.last 1000
  end
end
