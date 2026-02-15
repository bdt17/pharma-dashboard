require 'rails_helper'

RSpec.describe "Routes", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/routes/index"
      expect(response).to have_http_status(:success)
    end
  end

end
