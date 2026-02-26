module Api
  module V1
    class GpsController < ApplicationController
      skip_before_action :verify_authenticity_token
      def update; head :ok; end
      def stream; head :ok; end
    end
  end
end
