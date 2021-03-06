require 'rails_helper'

RSpec.describe "terms/new", type: :view do
  before(:each) do
    assign(:term, Term.new(
      name: "MyString",
      canvas_id: 1
    ))
  end

  it "renders new term form" do
    render

    assert_select "form[action=?][method=?]", terms_path, "post" do

      assert_select "input[name=?]", "term[name]"

      assert_select "input[name=?]", "term[canvas_id]"
    end
  end
end
