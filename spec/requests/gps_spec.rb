require 'rails_helper'

RSpec.describe "Gps", type: :request do
  describe "GET /update" do
    it "returns http success" do
      get "/gps/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /stream" do
    it "returns http success" do
      get "/gps/stream"
      expect(response).to have_http_status(:success)
    end
  end

end
