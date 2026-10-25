// Pinned in config/importmap.rb and served, but never actually imported
// anywhere -- ES modules only execute once something imports them, so
// Turbo's JS never ran at all despite loading successfully. That silently
// broke every link relying on data-turbo-method (link_to ..., data: {
// turbo_method: :delete }) -- clicking them fell back to a plain browser
// GET instead of the intended DELETE, e.g. signing out 404'd since
// DELETE /users/sign_out has no matching GET route.
import "@hotwired/turbo-rails"

import { Application } from "@hotwired/stimulus"
// eagerLoadControllersFrom is what stimulus-loading actually exports. The
// import here used to name `registerControllersFrom`, which doesn't exist --
// and in an ES module a missing named export is a link-time SyntaxError, so
// this whole file (Turbo included) never executed in any browser. The
// signature pad never mounted, which made recording a "delivered" custody
// event impossible from the UI. test/system/javascript_boot_test.rb guards it.
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
window.Stimulus = application
eagerLoadControllersFrom("controllers", application)
