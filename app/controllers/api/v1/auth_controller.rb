module Api
  module V1
    class AuthController < Api::BaseController
      # Skip auth check for this test endpoint

      def test_login
        username = params[:username]
        password = params[:password]

        if username == 'fda_auditor' && password == 'audit2026'
          render json: {
            token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fake-test-token',
            user: { id: 1, username: 'fda_auditor', role: 'auditor' },
            message: 'Test login successful'
          }, status: :ok
        else
          render json: { error: 'Invalid username or password' }, status: :unauthorized
        end
      end
    end
  end
end
