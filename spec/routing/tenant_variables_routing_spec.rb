require "rails_helper"

RSpec.describe TenantVariablesController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/tenant_variables").to route_to("tenant_variables#index")
    end

    it "routes to #new" do
      expect(get: "/tenant_variables/new").to route_to("tenant_variables#new")
    end

    it "routes to #show" do
      expect(get: "/tenant_variables/1").to route_to("tenant_variables#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/tenant_variables/1/edit").to route_to("tenant_variables#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/tenant_variables").to route_to("tenant_variables#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/tenant_variables/1").to route_to("tenant_variables#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/tenant_variables/1").to route_to("tenant_variables#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/tenant_variables/1").to route_to("tenant_variables#destroy", id: "1")
    end
  end
end
