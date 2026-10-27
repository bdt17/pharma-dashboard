require "test_helper"

class DeadlineOfferTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup { @organization = Organization.create!(name: "Dana Pharmacy") }

  test "the offer runs through December 31, 2026, independent of the DSCSA date" do
    assert DeadlineOffer.active?(on: Date.new(2026, 12, 31))
    assert_not DeadlineOffer.active?(on: Date.new(2027, 1, 1))
    assert_equal 5, DeadlineOffer.days_left(on: Date.new(2026, 12, 26))
    assert_equal "December 31, 2026", DeadlineOffer.label
  end

  test "claim! while the offer runs stamps the org and emails the operator once" do
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

  test "claim! after the offer ends does nothing" do
    travel_to Time.utc(2027, 1, 2, 15) do
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
