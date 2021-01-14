require 'rails_helper'

RSpec.describe "sections/show", type: :view do
  before(:each) do
    @section = assign(:section, Section.create!(
      name: "Name",
      sis_id: 2,
      course_id: 3,
      canvas_id: 4,
      canvas_course_id: 5,
      term_id: 6
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/6/)
  end
end
