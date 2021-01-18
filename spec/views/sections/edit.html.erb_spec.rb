require 'rails_helper'

RSpec.describe "sections/edit", type: :view do
  before(:each) do
    @course = assign(:course, Course.create!(
        name: "Math",
        sis_id: 1,
        course_length: 1
    ))
    @section = assign(:section, Section.create!(
      name: "Math - A Block",
      sis_id: 1,
      course_id: @course.id,
      canvas_id: 1,
      canvas_course_id: 1,
      term_id: 1
    ))
  end

  it "renders the edit section form" do
    render

    assert_select "form[action=?][method=?]", section_path(@section), "post" do

      assert_select "input[name=?]", "section[name]"

      assert_select "input[name=?]", "section[sis_id]"

      assert_select "input[name=?]", "section[course_id]"

      assert_select "input[name=?]", "section[canvas_id]"

      assert_select "input[name=?]", "section[canvas_course_id]"

      assert_select "input[name=?]", "section[term_id]"
    end
  end
end
