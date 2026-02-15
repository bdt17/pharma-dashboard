require 'rails_helper'

RSpec.describe "ChainOfCustodies", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/chain_of_custody/index"
      expect(response).to have_http_status(:success)
    end
  end

end
