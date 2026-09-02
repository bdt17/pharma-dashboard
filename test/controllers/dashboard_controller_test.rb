require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "dispatcher@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
  end

  test "requires authentication" do
    get dashboard_url, headers: { "Accept" => "text/html" }
    assert_redirected_to new_user_session_url
  end

  test "shows real counts and cross-organization data stays out" do
    Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    Batch.create!(lot_number: "LOT-BAD", temperature_celsius: 15, vehicle: @vehicle, organization: @organization)

    other_org = Organization.create!(name: "Other Org")
    other_vehicle = Vehicle.create!(name: "Truck 2", organization: other_org)
    Batch.create!(lot_number: "LOT-OTHER", temperature_celsius: 5, vehicle: other_vehicle, organization: other_org)

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_select "td", text: "LOT-BAD"
    assert_select "td", text: "LOT-OTHER", count: 0
  end

  test "shows recent custody events for the organization" do
    batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    batch.custody_logs.create!(action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ")

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_match "Phoenix, AZ", response.body
    assert_match "pickup", response.body
  end

  # A compliant batch never appears in the "Temperature excursions" table
  # (that only lists non-compliant ones), so recent custody events was the
  # only path from the dashboard to a batch's own page -- and it wasn't a
  # link at all before this.
  test "shows an in-progress temperature excursion with a link to the batch" do
    batch = Batch.create!(lot_number: "LOT-HOT", vehicle: @vehicle, organization: @organization, status: "active")
    ExcursionEvent.create!(batch: batch, vehicle: @vehicle, started_at: 20.minutes.ago, trigger_temp: 13.0, peak_temp: 14.2)

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_match "Live temperature excursions", response.body
    assert_select "td", text: "LOT-HOT"
    assert_select "a[href=?]", batch_custody_logs_path(batch)
  end

  test "shows the failed-payment recovery banner when the subscription is past_due" do
    @organization.update!(stripe_customer_id: "cus_123")
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_1", status: "past_due")

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_match "Your last payment didn't go through", response.body
    assert_select "form[action=?]", billing_portal_path
  end

  test "does not show the recovery banner when the subscription is active" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_1", status: "active")

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_no_match "Your last payment didn't go through", response.body
  end

  test "shows the card-expiry banner when the flag is set for a near period" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_1", status: "active")
    @organization.update!(card_expiry_notified_for: Date.current.strftime("%Y-%m"))

    sign_in @user
    get dashboard_url

    assert_match "The card on file is about to expire", response.body
    assert_select "form[action=?]", billing_portal_path
  end

  test "no card-expiry banner once the flag is cleared" do
    Subscription.sync_from_stripe!(organization: @organization, stripe_subscription_id: "sub_1", status: "active")

    sign_in @user
    get dashboard_url

    assert_no_match "The card on file is about to expire", response.body
  end

  test "a recent custody event links to its batch's custody history" do
    batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
    batch.custody_logs.create!(action_type: "pickup", handler_name: "Jane Doe", location: "Phoenix, AZ")

    sign_in @user
    get dashboard_url

    assert_response :success
    assert_select "a[href=?]", batch_custody_logs_path(batch), text: "LOT-1"
  end
end
