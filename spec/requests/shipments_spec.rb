require 'rails_helper'

RSpec.describe "Shipments", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/shipments/index"
      expect(response).to have_http_status(:success)
    end
  end

end
