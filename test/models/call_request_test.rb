require "test_helper"

class CallRequestTest < ActiveSupport::TestCase
  test "requires name, a valid email, and a known topic" do
    assert_not CallRequest.new(topic: "general").valid?

    cr = CallRequest.new(name: "Jane", email: "not-an-email", topic: "general")
    assert_not cr.valid?
    assert_includes cr.errors[:email], "is invalid"

    cr = CallRequest.new(name: "Jane", email: "jane@example.com", topic: "nope")
    assert_not cr.valid?
    assert_includes cr.errors[:topic], "is not included in the list"

    assert CallRequest.new(name: "Jane", email: "jane@example.com", topic: "general").valid?
    assert CallRequest.new(name: "Jane", email: "jane@example.com", topic: "enterprise").valid?
  end

  test "enterprise topic has a label" do
    assert_equal "Enterprise plan", CallRequest.new(topic: "enterprise").topic_label
  end

  test "topic_label is human readable" do
    assert_equal "Fractional compliance officer",
      CallRequest.new(topic: "compliance_officer").topic_label
  end

  test "unhandled scope excludes handled requests" do
    open = CallRequest.create!(name: "A", email: "a@example.com", topic: "general")
    CallRequest.create!(name: "B", email: "b@example.com", topic: "general", handled_at: Time.current)

    assert_equal [ open ], CallRequest.unhandled.to_a
  end
end
