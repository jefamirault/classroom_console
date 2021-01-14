require 'rails_helper'

RSpec.describe "terms/index", type: :view do
  before(:each) do
    assign(:terms, [
      Term.create!(
        name: "Name",
        canvas_id: 2
      ),
      Term.create!(
        name: "Name",
        canvas_id: 2
      )
    ])
  end

  it "renders a list of terms" do
    render
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: 2.to_s, count: 2
  end
end
