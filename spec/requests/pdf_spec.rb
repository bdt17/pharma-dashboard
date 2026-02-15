require 'rails_helper'

RSpec.describe "Pdfs", type: :request do
  describe "GET /test" do
    it "returns http success" do
      get "/pdf/test"
      expect(response).to have_http_status(:success)
    end
  end

end
