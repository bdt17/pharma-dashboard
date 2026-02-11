import { Application } from "@hotwired/stimulus"
import { registerControllersFrom } from "@hotwired/stimulus-loading"

const application = Application.start()
registerControllersFrom("controllers", application)
