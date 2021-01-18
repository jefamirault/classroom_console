require 'rails_helper'

RSpec.describe "tenant_variables/new", type: :view do
  before(:each) do
    assign(:tenant_variable, TenantVariable.new(
      name: "MyString",
      value: "MyString"
    ))
  end

  it "renders new tenant_variable form" do
    render

    assert_select "form[action=?][method=?]", tenant_variables_path, "post" do

      assert_select "input[name=?]", "tenant_variable[name]"

      assert_select "input[name=?]", "tenant_variable[value]"
    end
  end
end
