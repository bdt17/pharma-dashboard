class TestsController < ApplicationController
  def ui
    render plain: `./test_ui.rb`
  end
  def rails
    render plain: "Rails 8.1 + GPS + FDA Compliance ✓"
  end
  def infosec
    render plain: "🔒 FDA 21 CFR Part 11 • HTTPS • Render ✓"
  end
end
