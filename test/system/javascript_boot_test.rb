require "application_system_test_case"

# Guards the bug where app/javascript/application.js imported an export that
# doesn't exist, so Turbo and every Stimulus controller silently never ran in
# any browser -- while every other system test stayed green, because none of
# them needed JavaScript.
class JavascriptBootTest < ApplicationSystemTestCase
  # The custody form asks for the device location on load; give the browser
  # a fixed fix so the lookup resolves at once instead of hanging on a
  # permission prompt headless Chrome never answers.
  def fake_gps
    page.driver.browser.execute_cdp("Browser.grantPermissions", permissions: [ "geolocation" ])
    page.driver.browser.execute_cdp("Emulation.setGeolocationOverride", latitude: 33.448376, longitude: -112.074036, accuracy: 10)
  end

  test "Turbo and Stimulus boot on a page" do
    visit root_path

    assert_equal "object", evaluate_script("typeof window.Turbo")
    assert evaluate_script("!!(window.Stimulus && window.Stimulus.router)")
  end

  test "a delivered custody event can be signed and recorded from the real form" do
    organization = Organization.create!(name: "Northwind Pharmacy")
    password = "correct horse battery"
    User.create!(email: "dispatch@example.com", password: password, organization: organization, role: "dispatcher")
    vehicle = Vehicle.create!(name: "Truck 1", organization: organization)
    batch = Batch.create!(lot_number: "LOT-SIGN-1", temperature_celsius: 5, vehicle: vehicle, organization: organization)

    visit new_user_session_path
    fill_in "Email", with: "dispatch@example.com"
    fill_in "Password", with: password
    click_on "Sign in"
    assert_selector "h1", text: "Dashboard"

    fake_gps
    visit new_batch_custody_log_path(batch)
    assert_text "Location attached"
    find("label", text: "Delivered").click
    fill_in "Handler name", with: "Jane Doe"
    fill_in "Location", with: "Phoenix, AZ"
    fill_in "Signer name", with: "Sam Recipient"

    # Draw a stroke on the signature canvas the way a person would.
    canvas = find("canvas[data-signature-pad-target='canvas']").native
    page.driver.browser.action.move_to(canvas, -60, 0).click_and_hold.move_by(80, 20).move_by(40, -30).release.perform

    click_on "Record event"
    assert_no_selector "h1", text: "Record a custody event"

    log = batch.custody_logs.order(:created_at).last
    assert_equal "delivered", log.action_type
    assert log.signature_data["image"].start_with?("data:image/png;base64,"), "signature image was not captured"
    assert_equal "Sam Recipient", log.signature_data["signer_name"]
  end

  test "a driver lands on their deliveries and records a pickup from a phone-sized screen" do
    organization = Organization.create!(name: "Northwind Pharmacy")
    password = "correct horse battery"
    driver = User.create!(email: "driver@example.com", name: "Dana Driver", password: password, organization: organization, role: "driver")
    vehicle = Vehicle.create!(name: "Corolla", organization: organization)
    batch = Batch.create!(lot_number: "LOT-DRV-1", name: "Insulin glargine", vehicle: vehicle, organization: organization, driver: driver)

    page.driver.browser.manage.window.resize_to(390, 844)
    fake_gps
    visit new_user_session_path
    fill_in "Email", with: "driver@example.com"
    fill_in "Password", with: password
    click_on "Sign in"

    assert_selector "h1", text: "My deliveries"
    assert_text "Insulin glargine"
    click_on "Record pickup"

    assert_selector "h1", text: "Record a custody event"
    assert_text "Location attached"
    fill_in "Location", with: "Northwind Pharmacy, 12 Main St"
    fill_in "Product temperature °C (optional)", with: "4.4"
    click_on "Record event"
    assert_text "Custody event recorded."

    log = batch.custody_logs.last
    assert_equal "pickup", log.action_type
    assert_equal driver, log.recorded_by
    assert_equal BigDecimal("4.4"), log.temperature_celsius
    assert_equal BigDecimal("33.448376"), log.latitude
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
