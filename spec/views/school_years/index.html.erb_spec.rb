require 'rails_helper'

RSpec.describe "school_years/index", type: :view do
  before(:each) do
    assign(:school_years, [
      SchoolYear.create!(
        name: "Name"
      ),
      SchoolYear.create!(
        name: "Name"
      )
    ])
  end

  it "renders a list of school_years" do
    render
    cell_selector = Rails::VERSION::STRING >= '7' ? 'div>p' : 'tr>td'
    assert_select cell_selector, text: Regexp.new("Name".to_s), count: 2
  end
end
