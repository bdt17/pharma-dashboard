require "test_helper"

# Regression guard for a real bug: app/assets/javascripts/application.js
# was a leftover, empty Sprockets-era file that happened to share a name
# with the real entrypoint (app/javascript/application.js). Propshaft's
# load path checks app/assets/javascripts before app/javascript, so it
# silently served the empty stub instead -- meaning Turbo and every
# Stimulus controller in this app never actually ran in any browser, in
# any environment, without a single test or page-load error to show for
# it (the empty file is still perfectly valid, zero-byte JavaScript).
#
# This doesn't need a real browser to catch: it just needs to confirm
# Propshaft resolves "application.js" to a file that actually contains
# the bootstrapping code, not merely that *a* file exists at that path.
class JavascriptEntrypointTest < ActiveSupport::TestCase
  test "application.js resolves to the real entrypoint, not an empty shadow file" do
    asset = Rails.application.assets.load_path.find("application.js")

    assert_equal Rails.root.join("app/javascript/application.js"), asset.path
    content = asset.path.read
    assert_includes content, "@hotwired/turbo-rails"
    assert_includes content, "Application.start"
    assert_includes content, "registerControllersFrom"
  end
end
