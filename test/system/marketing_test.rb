require "application_system_test_case"

class MarketingTest < ApplicationSystemTestCase
  test "the home page renders full-bleed sections, not inside a narrow card" do
    visit root_path

    assert_selector "h1", text: "produce on demand"
    # The hero section must span the viewport -- the full_bleed regression
    # rendered every marketing page inside a ~1024px centred container.
    hero = find("section", match: :first)
    assert_operator hero.evaluate_script("this.getBoundingClientRect().width"), :>, 1200
  end

  test "the nav gets a signed-out visitor to sign-up and pricing" do
    visit root_path
    within("header") { click_on "Sign up" }
    assert_current_path new_user_registration_path

    visit root_path
    within("header") { click_on "Pricing" }
    assert_selector "h1", text: "Simple, transparent pricing."
  end

  test "pricing shows the self-serve tiers with their prices, plus Enterprise" do
    visit pricing_path

    assert_text "Starter"
    assert_text "Pro"
    assert_text "Compliance"
    assert_text "$99"
    assert_text "$249"
    assert_text "$499"
    assert_selector ".badge", text: "Most popular"

    assert_text "Enterprise"
    assert_link "Talk to us", href: request_a_call_path(topic: "enterprise")
  end

  test "the security page loads and states what is not yet claimed" do
    visit security_path
    assert_selector "h1", text: "survive an audit"
    assert_text "SOC 2 is on the roadmap"
  end
end
