require "test_helper"

class DeliveriesPrivacyTest < ActionDispatch::IntegrationTest
  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin")
    @dispatcher = User.create!(email: "disp@example.com", password: "password123!", organization: @org, role: "dispatcher")
  end

  test "admins see and change the setting, and it's audited" do
    sign_in @admin
    get deliveries_url
    assert_select "#privacy input[type=radio][value=approximate][checked]"

    patch deliveries_privacy_url, params: { delivery_gps_precision: "off" }
    assert_redirected_to deliveries_path(anchor: "privacy")
    assert_equal "off", @org.reload.delivery_gps_precision
    assert AuditLog.exists?(event: "delivery_gps_precision_changed")
  end

  test "rejects unknown values" do
    sign_in @admin
    patch deliveries_privacy_url, params: { delivery_gps_precision: "street" }
    assert_equal "approximate", @org.reload.delivery_gps_precision
  end

  test "non-admins can't see or change it" do
    sign_in @dispatcher
    get deliveries_url
    assert_select "#privacy", count: 0

    patch deliveries_privacy_url, params: { delivery_gps_precision: "exact" }
    assert_equal "approximate", @org.reload.delivery_gps_precision
  end
end
