require 'rails_helper'

RSpec.describe "sections/new", type: :view do
  before(:each) do
    assign(:section, Section.new(
      name: "MyString",
      sis_id: 1,
      course_id: 1,
      canvas_id: 1,
      canvas_course_id: 1,
      term_id: 1
    ))
  end

  it "renders new section form" do
    render

    assert_select "form[action=?][method=?]", sections_path, "post" do

      assert_select "input[name=?]", "section[name]"

      assert_select "input[name=?]", "section[sis_id]"

      assert_select "input[name=?]", "section[course_id]"

      assert_select "input[name=?]", "section[canvas_id]"

      assert_select "input[name=?]", "section[canvas_course_id]"

      assert_select "input[name=?]", "section[term_id]"
    end
  end
end
