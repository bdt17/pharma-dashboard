require "test_helper"

class AlertSettingsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @admin = User.create!(email: "admin@example.com", password: "password123!", organization: @organization, role: "admin")
    @dispatcher = User.create!(email: "dispatch@example.com", password: "password123!", organization: @organization, role: "dispatcher")
  end

  def enable_sms
    Subscription.create!(organization: @organization, status: "active", stripe_subscription_id: "sub_pro", tier: "pro")
  end

  test "requires authentication" do
    get alert_settings_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "shows the upgrade prompt when the plan doesn't include SMS" do
    sign_in @dispatcher
    get alert_settings_url

    assert_response :success
    assert_match "SMS alerts are included on the", response.body
    assert_select "a[href=?]", billing_path
  end

  test "shows the add-number form for an admin on an eligible plan" do
    enable_sms
    sign_in @admin
    get alert_settings_url

    assert_response :success
    assert_select "form[action=?]", alert_recipients_path
  end

  test "an admin can add a recipient" do
    enable_sms
    sign_in @admin

    assert_difference -> { @organization.alert_recipients.count }, 1 do
      post alert_recipients_url, params: { alert_recipient: { label: "On call", phone: "415-555-0100" } }
    end

    assert_redirected_to alert_settings_path
    assert_equal "+14155550100", @organization.alert_recipients.last.phone
  end

  test "an invalid number re-renders with the error" do
    enable_sms
    sign_in @admin

    assert_no_difference -> { AlertRecipient.count } do
      post alert_recipients_url, params: { alert_recipient: { label: "Bad", phone: "nope" } }
    end
    assert_response :unprocessable_content
    assert_match "international format", response.body
  end

  test "a non-admin cannot add a recipient" do
    enable_sms
    sign_in @dispatcher

    assert_no_difference -> { AlertRecipient.count } do
      post alert_recipients_url, params: { alert_recipient: { label: "On call", phone: "+14155550100" } }
    end
    assert_redirected_to alert_settings_path
    follow_redirect!
    assert_match "Only an organization admin", response.body
  end

  test "adding is refused when the plan doesn't include SMS" do
    sign_in @admin

    assert_no_difference -> { AlertRecipient.count } do
      post alert_recipients_url, params: { alert_recipient: { label: "On call", phone: "+14155550100" } }
    end
    assert_redirected_to alert_settings_path
  end

  test "an admin can remove a recipient" do
    enable_sms
    recipient = @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
    sign_in @admin

    assert_difference -> { @organization.alert_recipients.count }, -1 do
      delete alert_recipient_url(recipient)
    end
    assert_redirected_to alert_settings_path
  end

  test "one organization cannot remove another's recipient" do
    other = Organization.create!(name: "Other Pharma")
    theirs = other.alert_recipients.create!(label: "Theirs", phone: "+14155550100")
    sign_in @admin

    delete alert_recipient_url(theirs)

    assert_response :not_found
    assert AlertRecipient.exists?(theirs.id)
  end

  test "an admin can queue a test SMS to a recipient" do
    enable_sms
    recipient = @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
    sign_in @admin

    assert_enqueued_with(job: SmsTestJob, args: [ recipient.id ]) do
      post test_alert_recipient_url(recipient)
    end
    assert_redirected_to alert_settings_path
    follow_redirect!
    assert_match "Test message queued", response.body
  end

  test "a non-admin cannot send a test SMS" do
    enable_sms
    recipient = @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
    sign_in @dispatcher

    assert_no_enqueued_jobs only: SmsTestJob do
      post test_alert_recipient_url(recipient)
    end
    assert_redirected_to alert_settings_path
  end

  test "a test SMS is refused without an eligible plan" do
    recipient = @organization.alert_recipients.create!(label: "On call", phone: "+14155550100")
    sign_in @admin

    assert_no_enqueued_jobs only: SmsTestJob do
      post test_alert_recipient_url(recipient)
    end
    assert_redirected_to alert_settings_path
  end

  test "an admin can turn quiet hours on and set the timezone together" do
    enable_sms
    sign_in @admin

    patch alert_quiet_hours_url, params: { organization: { sms_quiet_hours_enabled: "1", time_zone: "Pacific Time (US & Canada)" } }

    assert_redirected_to alert_settings_path
    @organization.reload
    assert @organization.sms_quiet_hours_enabled?
    assert_equal "Pacific Time (US & Canada)", @organization.time_zone
    follow_redirect!
    assert_match "Quiet hours are on", response.body
  end

  test "turning quiet hours off doesn't require or clear the timezone" do
    enable_sms
    @organization.update!(sms_quiet_hours_enabled: true, time_zone: "Pacific Time (US & Canada)")
    sign_in @admin

    patch alert_quiet_hours_url, params: { organization: { sms_quiet_hours_enabled: "0" } }

    @organization.reload
    assert_not @organization.sms_quiet_hours_enabled?
    assert_equal "Pacific Time (US & Canada)", @organization.time_zone # untouched
  end

  test "a non-admin cannot change quiet hours" do
    enable_sms
    sign_in @dispatcher

    patch alert_quiet_hours_url, params: { organization: { sms_quiet_hours_enabled: "1" } }

    assert_not @organization.reload.sms_quiet_hours_enabled?
    assert_redirected_to alert_settings_path
  end

  test "an invalid timezone is rejected with a clear error, not silently dropped" do
    enable_sms
    sign_in @admin

    patch alert_quiet_hours_url, params: { organization: { sms_quiet_hours_enabled: "1", time_zone: "Not/AZone" } }

    assert_not @organization.reload.sms_quiet_hours_enabled?
    follow_redirect!
    assert_match "is not included in the list", response.body
  end

  test "an admin can turn all-clear texts on and off" do
    enable_sms
    sign_in @admin

    patch alert_all_clear_url(enabled: true)
    assert @organization.reload.all_clear_sms_enabled?
    assert_redirected_to alert_settings_path
    follow_redirect!
    assert_match "All-clear texts are on", response.body

    patch alert_all_clear_url(enabled: false)
    assert_not @organization.reload.all_clear_sms_enabled?
  end

  test "a non-admin cannot change all-clear texts" do
    enable_sms
    sign_in @dispatcher

    patch alert_all_clear_url(enabled: true)

    assert_not @organization.reload.all_clear_sms_enabled?
    assert_redirected_to alert_settings_path
  end
end
