require "test_helper"

class ConversionTrackingHelperTest < ActionView::TestCase
  def with_env(overrides)
    original = ENV.to_h
    overrides.each { |k, v| v.nil? ? ENV.delete(k) : ENV[k] = v }
    yield
  ensure
    ENV.replace(original)
  end

  test "base tag renders nothing until GOOGLE_ADS_CONVERSION_ID is set" do
    with_env("GOOGLE_ADS_CONVERSION_ID" => nil) do
      assert_nil google_ads_base_tag
    end
  end

  test "base tag loads gtag.js and configures the account when the id is set" do
    with_env("GOOGLE_ADS_CONVERSION_ID" => "AW-123456789") do
      html = google_ads_base_tag
      assert_includes html, "https://www.googletagmanager.com/gtag/js?id=AW-123456789"
      assert_includes html, %(gtag('config', "AW-123456789"))
      assert_includes html, "async"
    end
  end

  test "a conversion event stays silent when its label env var is missing" do
    with_env("GOOGLE_ADS_CONVERSION_ID" => "AW-123456789", "GOOGLE_ADS_LABEL_ASSESSMENT" => nil) do
      assert_nil google_ads_conversion(:assessment)
    end
  end

  test "a conversion event stays silent when the account id is missing" do
    with_env("GOOGLE_ADS_CONVERSION_ID" => nil, "GOOGLE_ADS_LABEL_CALL" => "abc123") do
      assert_nil google_ads_conversion(:call)
    end
  end

  test "a conversion event fires against send_to id/label when both are set" do
    with_env("GOOGLE_ADS_CONVERSION_ID" => "AW-123456789", "GOOGLE_ADS_LABEL_TRIAL" => "AbC-d1e2F3") do
      html = google_ads_conversion(:trial)
      assert_includes html, %(gtag('event', 'conversion', {send_to: "AW-123456789/AbC-d1e2F3"}))
    end
  end

  test "an unknown event key raises rather than firing a malformed tag" do
    assert_raises(KeyError) { google_ads_conversion(:nope) }
  end
end
