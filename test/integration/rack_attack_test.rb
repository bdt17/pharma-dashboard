require "test_helper"

# Rack::Attack uses Rails.cache as its throttle store, and test.rb sets
# config.cache_store = :null_store -- so throttle counts never actually
# persist between requests in the test suite by default. These tests swap
# in a real in-memory store just long enough to prove the throttles are
# wired up and firing, then restore the null store.
class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    @previous_cache = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.cache.store = @previous_cache
    Rack::Attack.reset!
  end

  test "throttles repeated login attempts from the same IP" do
    11.times do
      post user_session_path, params: { user: { email: "nobody@example.com", password: "wrong" } }
    end

    assert_response :too_many_requests
  end

  test "throttles repeated signup attempts from the same IP" do
    6.times do |n|
      post user_registration_path, params: {
        user: { organization_name: "Org #{n}", email: "signup#{n}@example.com",
                password: "password123!", password_confirmation: "password123!", terms_accepted: "1" }
      }
    end

    assert_response :too_many_requests
  end

  test "throttles repeated two-factor challenge attempts from the same IP" do
    user = User.create!(
      email: "challenged@example.com", password: "password123!",
      organization: Organization.create!(name: "Acme"), role: "dispatcher"
    )
    user.generate_otp_secret!
    user.enable_two_factor!
    post user_session_path, params: { user: { email: user.email, password: "password123!" } }

    # freeze_time so every attempt lands in the same throttle period regardless
    # of how slow the suite runs.
    freeze_time do
      11.times { post two_factor_challenge_path, params: { otp_code: "000000" } }
    end

    assert_response :too_many_requests
  end

  test "throttles repeated two-factor setup attempts from the same IP" do
    user = User.create!(
      email: "enrolling@example.com", password: "password123!",
      organization: Organization.create!(name: "Acme"), role: "dispatcher"
    )
    sign_in user

    freeze_time do
      11.times { post two_factor_setup_path, params: { otp_code: "000000" } }
    end

    assert_response :too_many_requests
  end
end
