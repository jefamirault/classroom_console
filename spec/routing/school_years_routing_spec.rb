require "rails_helper"

RSpec.describe SchoolYearsController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/school_years").to route_to("school_years#index")
    end

    it "routes to #new" do
      expect(get: "/school_years/new").to route_to("school_years#new")
    end

    it "routes to #show" do
      expect(get: "/school_years/1").to route_to("school_years#show", id: "1")
    end

    it "routes to #edit" do
      expect(get: "/school_years/1/edit").to route_to("school_years#edit", id: "1")
    end


    it "routes to #create" do
      expect(post: "/school_years").to route_to("school_years#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/school_years/1").to route_to("school_years#update", id: "1")
    end

    it "routes to #update via PATCH" do
      expect(patch: "/school_years/1").to route_to("school_years#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete: "/school_years/1").to route_to("school_years#destroy", id: "1")
    end
  end
end
