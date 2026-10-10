require 'rails_helper'

RSpec.describe "Masquerade", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { FactoryBot.create :user, login_enabled: true, password: 'password123' }
  let(:teacher) { FactoryBot.create :user }

  describe "POST /masquerade/:user_id" do
    it "lets an admin view the app as another user and logs it" do
      sign_in admin
      expect { post masquerade_path(teacher) }.to change { Event.where(label: 'Masquerade Start').count }.by(1)
      expect(response).to redirect_to(user_path(teacher))

      follow_redirect!
      expect(response.body).to include("Viewing as <strong>#{teacher}</strong>")
    end

    it "is forbidden for a user who is not an admin" do
      sign_in teacher
      post masquerade_path(admin)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /masquerade" do
    it "returns the admin to their own session and logs it" do
      sign_in admin
      post masquerade_path(teacher)
      expect { delete stop_masquerade_path }.to change { Event.where(label: 'Masquerade Stop').count }.by(1)

      follow_redirect!
      expect(response.body).not_to include("Viewing as")
      expect(response.body).to include("View as this user")
    end
  end
end

RSpec.describe "Dev login", type: :request do
  it "is not routable outside development" do
    expect { Rails.application.routes.recognize_path('/dev/login', method: :post) }
      .to raise_error(ActionController::RoutingError)
    expect { Rails.application.routes.recognize_path('/dev/login', method: :get) }
      .to raise_error(ActionController::RoutingError)
  end
end
