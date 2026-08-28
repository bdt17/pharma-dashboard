ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # Fixtures are declared explicitly by tests that need them.

    # Add more helper methods to be used by all tests here...
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end

# Two-factor is required for every user (ApplicationController#enforce_two_factor),
# which would otherwise redirect every `sign_in`-based controller test to the
# enrollment page. Devise::Test's `sign_in` sets the user with no winning
# Warden strategy (it skips the real login flow), so use that to mark the
# second factor satisfied for helper-based logins only. Tests that exercise
# the real gate POST actual credentials -- those have a winning strategy and a
# :fetch on every later request, both excluded here, so the gate still applies.
Warden::Manager.after_set_user do |user, auth, opts|
  next unless user.is_a?(User)
  next if opts[:event] == :fetch
  next unless auth.winning_strategy.nil?

  auth.session(:user)["mfa_passed"] = true
end
