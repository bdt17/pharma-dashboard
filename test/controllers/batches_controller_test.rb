require "test_helper"

class BatchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
    @user = User.create!(email: "dispatcher@example.com", password: "password123!", organization: @organization, role: "dispatcher")
    @vehicle = Vehicle.create!(name: "Truck 1", organization: @organization)
    @batch = Batch.create!(lot_number: "LOT-1", temperature_celsius: 5, vehicle: @vehicle, organization: @organization)
  end

  test "chain_of_custody requires authentication" do
    get batch_chain_of_custody_pdf_url(@batch), headers: html_accept
    assert_redirected_to new_user_session_url
  end

  test "chain_of_custody returns a real PDF for a batch in the user's organization" do
    sign_in @user
    get batch_chain_of_custody_pdf_url(@batch), headers: html_accept

    assert_response :success
    assert_equal "application/pdf", response.media_type
    assert response.body.start_with?("%PDF"), "expected a real PDF, got: #{response.body[0, 20].inspect}"
  end

  test "chain_of_custody records an audit log entry" do
    sign_in @user

    assert_difference -> { AuditLog.count }, 1 do
      get batch_chain_of_custody_pdf_url(@batch), headers: html_accept
    end

    log = AuditLog.last
    assert_equal "chain_of_custody_pdf_generated", log.event
    assert_equal @user, log.user
    assert_equal @batch, log.batch
  end

  test "chain_of_custody redirects away (does not serve the PDF) for a batch in a different organization" do
    other_org = Organization.create!(name: "Other Org")
    other_batch = Batch.create!(lot_number: "LOT-2", temperature_celsius: 5, vehicle: @vehicle, organization: other_org)

    sign_in @user
    get batch_chain_of_custody_pdf_url(other_batch), headers: html_accept

    assert_redirected_to root_url
  end

  private

  def html_accept
    { "Accept" => "text/html" }
  end
end
