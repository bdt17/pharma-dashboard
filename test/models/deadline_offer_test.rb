require "test_helper"

class DeadlineOfferTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup { @organization = Organization.create!(name: "Dana Pharmacy") }

  test "claim! before the deadline stamps the org and emails the operator once" do
    travel_to Time.utc(2026, 11, 1, 15) do
      assert_enqueued_emails 1 do
        assert DeadlineOffer.claim!(@organization)
      end
      assert @organization.reload.free_setup_owed_at

      assert_no_enqueued_emails do
        assert_not DeadlineOffer.claim!(@organization)
      end
    end
  end

  test "claim! after the deadline does nothing" do
    travel_to Time.utc(2026, 11, 29, 15) do
      assert_no_enqueued_emails do
        assert_not DeadlineOffer.claim!(@organization)
      end
    end
    assert_nil @organization.reload.free_setup_owed_at
  end

  test "the value comes from the White-Glove Setup price" do
    assert_equal "$299", DeadlineOffer.value_label
  end
end
