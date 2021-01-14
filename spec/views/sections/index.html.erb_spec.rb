require 'rails_helper'

RSpec.describe "sections/index", type: :view do
  before(:each) do
    assign(:sections, [
      Section.create!(
        name: "Name",
        sis_id: 2,
        course_id: 3,
        canvas_id: 4,
        canvas_course_id: 5,
        term_id: 6
      ),
      Section.create!(
        name: "Name",
        sis_id: 2,
        course_id: 3,
        canvas_id: 4,
        canvas_course_id: 5,
        term_id: 6
      )
    ])
  end

  it "renders a list of sections" do
    render
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
    assert_select "tr>td", text: 3.to_s, count: 2
    assert_select "tr>td", text: 4.to_s, count: 2
    assert_select "tr>td", text: 5.to_s, count: 2
    assert_select "tr>td", text: 6.to_s, count: 2
  end
end
