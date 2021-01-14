require 'rails_helper'

RSpec.describe "courses/new", type: :view do
  before(:each) do
    assign(:course, Course.new(
      name: "MyString",
      sis_id: 1,
      is_active: false,
      course_length: 1
    ))
  end

  it "renders new course form" do
    render

    assert_select "form[action=?][method=?]", courses_path, "post" do

      assert_select "input[name=?]", "course[name]"

      assert_select "input[name=?]", "course[sis_id]"

      assert_select "input[name=?]", "course[is_active]"

      assert_select "input[name=?]", "course[course_length]"
    end
  end
end
