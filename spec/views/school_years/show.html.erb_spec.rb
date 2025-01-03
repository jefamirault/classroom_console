require 'rails_helper'

RSpec.describe "school_years/show", type: :view do
  before(:each) do
    assign(:school_year, SchoolYear.create!(
      name: "Name"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
  end
end
