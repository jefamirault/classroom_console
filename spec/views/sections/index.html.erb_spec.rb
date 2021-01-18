require 'rails_helper'

RSpec.describe "sections/index", type: :view do
  before(:each) do
    @course = assign(:course, Course.create!(
        name: "Math",
        sis_id: 1,
        course_length: 1
    ))
    assign(:sections, [
      Section.create!(
        name: "Math - A Block",
        sis_id: 299,
        course_id: @course.id,
        canvas_id: 4,
        canvas_course_id: 5,
        term_id: 6
      ),
      Section.create!(
        name: "Math - C Block",
        sis_id: 300,
        course_id: @course.id,
        canvas_id: 4,
        canvas_course_id: 5,
        term_id: 6
      )
    ])
  end

  it "renders a list of sections" do
    render
    assert_select "tr>td", text: "Math - A Block", count: 1
    assert_select "tr>td", text: "Math - C Block", count: 1
    assert_select "tr>td", text: 4.to_s, count: 2
    assert_select "tr>td", text: 5.to_s, count: 2
    assert_select "tr>td", text: 6.to_s, count: 2
  end
end
