require "test_helper"

class AlertRecipientTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme Pharma")
  end

  test "normalizes a 10-digit US number to E.164" do
    recipient = @organization.alert_recipients.create!(label: "On call", phone: "(415) 555-0100")
    assert_equal "+14155550100", recipient.phone
  end

  test "keeps an already-international number, stripping punctuation" do
    recipient = @organization.alert_recipients.create!(label: "UK office", phone: "+44 20 7946 0018")
    assert_equal "+442079460018", recipient.phone
  end

  test "rejects a number that isn't valid E.164 after normalizing" do
    recipient = @organization.alert_recipients.build(label: "Bad", phone: "12345")
    assert_not recipient.valid?
    assert_includes recipient.errors[:phone].join, "international format"
  end

  test "requires a label" do
    recipient = @organization.alert_recipients.build(phone: "+14155550100")
    assert_not recipient.valid?
    assert_includes recipient.errors[:label], "can't be blank"
  end

  test "the same number can't be added twice for one organization" do
    @organization.alert_recipients.create!(label: "First", phone: "+14155550100")
    dupe = @organization.alert_recipients.build(label: "Second", phone: "415-555-0100")

    assert_not dupe.valid?
    assert_includes dupe.errors[:phone].join, "already on the list"
  end

  test "the active scope excludes deactivated recipients" do
    on = @organization.alert_recipients.create!(label: "On", phone: "+14155550100")
    off = @organization.alert_recipients.create!(label: "Off", phone: "+14155550101", active: false)

    assert_includes AlertRecipient.active, on
    assert_not_includes AlertRecipient.active, off
  end
end
