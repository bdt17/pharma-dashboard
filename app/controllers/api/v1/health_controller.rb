module Api
  module V1
    class HealthController < ApplicationController
      skip_before_action :verify_authenticity_token
      skip_before_action :enforce_two_factor
      def show
        render json: { status: "ok", timestamp: Time.now.to_i }
      end
    end
  end
end
