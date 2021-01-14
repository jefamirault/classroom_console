require 'rails_helper'

RSpec.describe "terms/show", type: :view do
  before(:each) do
    @term = assign(:term, Term.create!(
      name: "Name",
      canvas_id: 2
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/2/)
  end
end
