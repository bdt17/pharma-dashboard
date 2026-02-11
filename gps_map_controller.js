import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["placeholder"]
  static values = { apiKey: String, autoRefresh: Boolean }

  connect() {
    console.log("GPS Map controller connected")
    this.element.innerHTML = "<div>✅ GPS Map instance ready. Add Mapbox/Google Maps here.</div>"
  }

  refresh() {
    console.log("GPS refresh called")
  }
}
