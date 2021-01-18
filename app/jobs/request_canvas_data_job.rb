class RequestCanvasDataJob < ApplicationJob
  queue_as :default

  include ExportHelper

  def perform(*args)
    canvas_sections_json = read_json 'canvas_sections.json'
    Section.match_canvas_ids canvas_sections_json
  end
end