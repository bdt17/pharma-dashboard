require 'rails_helper'

RSpec.describe "Trucks", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/trucks/index"
      expect(response).to have_http_status(:success)
    end
  end

end
