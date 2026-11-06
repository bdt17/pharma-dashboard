require "test_helper"

class OnboardingMailerTest < ActionMailer::TestCase
  setup do
    @org = Organization.create!(name: "Main Street Rx")
    @admin = User.create!(email: "owner@example.com", password: "password123!", organization: @org, role: "admin", name: "Dana Ruiz")
  end

  def bodies(mail) = [ mail.html_part.body.to_s, mail.text_part.body.to_s ]

  test "day 1 leads with the first unfinished step and an unsubscribe header" do
    mail = OnboardingMailer.nudge(@admin, 1)
    assert_equal [ "owner@example.com" ], mail.to
    assert_equal "Your first delivery record takes about 10 minutes", mail.subject
    assert_match(/<.*unsubscribe.*>/, mail["List-Unsubscribe"].to_s)
    bodies(mail).each do |body|
      assert_includes body, "Hi Dana"
      assert_includes body, "Add your delivery vehicle"
      assert_includes body, "/vehicles/new"
      assert_includes body, "Invite your driver"
      assert_includes body, "sample shipments"
    end
  end

  test "points at the next step as the org progresses" do
    vehicle = Vehicle.create!(name: "Van", organization: @org)
    mail = OnboardingMailer.nudge(@admin, 2)
    assert_equal "Next step for Main Street Rx: log your first batch", mail.subject
    assert_includes mail.text_part.body.to_s, "1 of 3 steps"

    Batch.create!(lot_number: "LOT-1", vehicle: vehicle, organization: @org)
    mail = OnboardingMailer.nudge(@admin, 2)
    assert_includes mail.subject, "record a pickup and delivery"
    assert_not_includes mail.text_part.body.to_s, "sample shipments"
  end

  test "sample data alone doesn't advance the steps" do
    SampleData.load!(@org, user: @admin)
    mail = OnboardingMailer.nudge(@admin, 2)
    assert_includes mail.subject, "add your delivery vehicle"
  end

  test "day 7 offers a call, and the free-setup line follows the offer" do
    travel_to Time.utc(2026, 11, 10, 16) do
      mail = OnboardingMailer.nudge(@admin, 3)
      assert_equal "Want a hand setting up Pharma Transport?", mail.subject
      assert_includes mail.text_part.body.to_s, "Book a 20-minute call"
      assert_includes mail.text_part.body.to_s, "before #{DeadlineOffer.label}"
    end

    travel_to Time.utc(2027, 1, 5, 16) do
      assert_not_includes OnboardingMailer.nudge(@admin, 3).text_part.body.to_s, "free"
    end

    @org.update!(free_setup_owed_at: Time.current)
    assert_includes OnboardingMailer.nudge(@admin, 3).text_part.body.to_s, "Your free setup call is included"
  end

  test "trial notice gives the date, the plan, and how to stop" do
    sub = Subscription.create!(organization: @org, status: "trialing", tier: "starter", current_period_end: Time.utc(2026, 11, 20, 12))
    mail = OnboardingMailer.trial_ending(@admin, sub)
    assert_equal "Your Pharma Transport trial ends November 20", mail.subject
    bodies(mail).each do |body|
      assert_includes body, "November 20, 2026"
      assert_includes body, "Starter plan"
      assert_includes body, "won"
      assert_includes body, "/billing"
    end
    assert_nil mail["List-Unsubscribe"]
  end
end
