// Pinned in config/importmap.rb and served, but never actually imported
// anywhere -- ES modules only execute once something imports them, so
// Turbo's JS never ran at all despite loading successfully. That silently
// broke every link relying on data-turbo-method (link_to ..., data: {
// turbo_method: :delete }) -- clicking them fell back to a plain browser
// GET instead of the intended DELETE, e.g. signing out 404'd since
// DELETE /users/sign_out has no matching GET route.
import "@hotwired/turbo-rails"

import { Application } from "@hotwired/stimulus"
import { registerControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
registerControllersFrom("controllers", application)
