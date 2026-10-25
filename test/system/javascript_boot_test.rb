require "application_system_test_case"

# Guards the bug where app/javascript/application.js imported an export that
# doesn't exist, so Turbo and every Stimulus controller silently never ran in
# any browser -- while every other system test stayed green, because none of
# them needed JavaScript.
class JavascriptBootTest < ApplicationSystemTestCase
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

    visit new_batch_custody_log_path(batch)
    select "delivered", from: "Action type"
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
end
