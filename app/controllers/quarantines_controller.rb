class QuarantinesController < ApplicationController
  def index
    @quarantines = Quarantine.all
  end
end