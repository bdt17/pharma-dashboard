require 'rails_helper'

RSpec.describe "Batches", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/batches/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/batches/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /chain_of_custody" do
    it "returns http success" do
      get "/batches/chain_of_custody"
      expect(response).to have_http_status(:success)
    end
  end

end
