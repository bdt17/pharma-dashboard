require "test_helper"

class AlertSettingsControllerTest < ActionDispatch::IntegrationTest
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
end
