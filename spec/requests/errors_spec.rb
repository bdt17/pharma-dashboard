require 'rails_helper'

RSpec.describe "Errors", type: :request do
  describe "GET /error404" do
    it "returns http success" do
      get "/errors/error404"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /error500" do
    it "returns http success" do
      get "/errors/error500"
      expect(response).to have_http_status(:success)
    end
  end

end
