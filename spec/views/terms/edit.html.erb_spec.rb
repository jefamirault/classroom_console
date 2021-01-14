require 'rails_helper'

RSpec.describe "terms/edit", type: :view do
  before(:each) do
    @term = assign(:term, Term.create!(
      name: "MyString",
      canvas_id: 1
    ))
  end

  it "renders the edit term form" do
    render

    assert_select "form[action=?][method=?]", term_path(@term), "post" do

      assert_select "input[name=?]", "term[name]"

      assert_select "input[name=?]", "term[canvas_id]"
    end
  end
end
