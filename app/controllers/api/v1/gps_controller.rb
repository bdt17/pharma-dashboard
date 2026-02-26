module Api
  module V1
    class GpsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:update, :stream]
      
      def update
        # GPS truck telemetry endpoint
        head :ok
      end
      
      def stream
        # GPS real-time stream
        head :ok
      end
    end
  end
end
