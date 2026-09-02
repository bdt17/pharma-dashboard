require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ] do |options|
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
  end

  # Chrome's CDP layer intermittently raises
  #   Selenium::WebDriver::Error::UnknownError:
  #     "Node with given id does not belong to the document"
  # when Capybara reads an element's text while a Turbo navigation is
  # detaching that node. It is not in Capybara's own retry list (it's an
  # UnknownError, not a StaleElementReferenceError), so it surfaces as a
  # hard failure even though re-checking a moment later always passes.
  # Rather than sprinkle `visible: :all` on individual selectors (which
  # only dodges the text read), retry the whole assertion once.
  TRANSIENT_NODE_ERROR = "Node with given id does not belong to the document".freeze

  %i[assert_selector assert_no_selector assert_text assert_no_text].each do |matcher|
    define_method(matcher) do |*args, **kwargs, &block|
      super(*args, **kwargs, &block)
    rescue Selenium::WebDriver::Error::UnknownError => e
      raise unless e.message.include?(TRANSIENT_NODE_ERROR)

      sleep 0.15
      super(*args, **kwargs, &block)
    end
  end
end
