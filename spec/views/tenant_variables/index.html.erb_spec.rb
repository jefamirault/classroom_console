require 'rails_helper'

RSpec.describe "tenant_variables/index", type: :view do
  before(:each) do
    assign(:tenant_variables, [
      TenantVariable.create!(
        name: "Name",
        value: "Value"
      ),
      TenantVariable.create!(
        name: "Name",
        value: "Value"
      )
    ])
  end

  it "renders a list of tenant_variables" do
    render
    assert_select "tr>td", text: "Name".to_s, count: 2
    assert_select "tr>td", text: "Value".to_s, count: 2
  end
end
