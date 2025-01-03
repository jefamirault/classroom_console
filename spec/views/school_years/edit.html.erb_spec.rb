require 'rails_helper'

RSpec.describe "school_years/edit", type: :view do
  let(:school_year) {
    SchoolYear.create!(
      name: "MyString"
    )
  }

  before(:each) do
    assign(:school_year, school_year)
  end

  it "renders the edit school_year form" do
    render

    assert_select "form[action=?][method=?]", school_year_path(school_year), "post" do

      assert_select "input[name=?]", "school_year[name]"
    end
  end
end
