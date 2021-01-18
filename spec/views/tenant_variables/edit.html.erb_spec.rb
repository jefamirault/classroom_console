require 'rails_helper'

RSpec.describe "tenant_variables/edit", type: :view do
  before(:each) do
    @tenant_variable = assign(:tenant_variable, TenantVariable.create!(
      name: "MyString",
      value: "MyString"
    ))
  end

  it "renders the edit tenant_variable form" do
    render

    assert_select "form[action=?][method=?]", tenant_variable_path(@tenant_variable), "post" do

      assert_select "input[name=?]", "tenant_variable[name]"

      assert_select "input[name=?]", "tenant_variable[value]"
    end
  end
end
