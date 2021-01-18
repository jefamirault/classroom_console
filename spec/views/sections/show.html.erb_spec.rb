require 'rails_helper'

RSpec.describe "sections/show", type: :view do
  before(:each) do
    @course = assign(:course, Course.create!(
        name: "Math",
        sis_id: 1,
        course_length: 1
    ))
    @section = assign(:section, Section.create!(
      name: "Math - A Block",
      sis_id: 2,
      course_id: @course.id,
      canvas_id: 4,
      canvas_course_id: 5,
      term_id: 6
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/#{@course.name}/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/6/)
  end
end
