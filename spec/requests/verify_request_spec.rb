require 'rails_helper'

RSpec.describe "Verifies", type: :request do

  describe "GET /index" do
    it "returns http success" do
      get "/public"
      expect(response).to have_http_status(:success)
    end
  end

end
