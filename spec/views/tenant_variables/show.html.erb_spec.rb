require 'rails_helper'

RSpec.describe "tenant_variables/show", type: :view do
  before(:each) do
    @tenant_variable = assign(:tenant_variable, TenantVariable.create!(
      name: "Name",
      value: "Value"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Value/)
  end
end
