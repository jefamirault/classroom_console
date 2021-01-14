require 'rails_helper'

RSpec.describe "courses/edit", type: :view do
  before(:each) do
    @course = assign(:course, Course.create!(
      name: "MyString",
      sis_id: 1,
      is_active: false,
      course_length: 1
    ))
  end

  it "renders the edit course form" do
    render

    assert_select "form[action=?][method=?]", course_path(@course), "post" do

      assert_select "input[name=?]", "course[name]"

      assert_select "input[name=?]", "course[sis_id]"

      assert_select "input[name=?]", "course[is_active]"

      assert_select "input[name=?]", "course[course_length]"
    end
  end
end
