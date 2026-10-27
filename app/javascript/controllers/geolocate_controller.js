import { Controller } from "@hotwired/stimulus"

// Driver mode: attaches the phone's GPS position to a custody event. Asks
// as soon as the form opens (that's the moment of handoff), and again on
// "Retry". Only this page's Permissions-Policy allows geolocation -- see
// CustodyLogsController#allow_geolocation. A refused or failed fix never
// blocks the form: location stays a typed field.
export default class extends Controller {
  static targets = ["latitude", "longitude", "accuracy", "status", "retry"]

  connect() {
    if (!("geolocation" in navigator)) {
      this.show("This device can't share its location. Type the address instead.")
      return
    }
    this.locate()
  }

  locate() {
    this.show("Getting your location…")
    this.retryTarget.hidden = true
    navigator.geolocation.getCurrentPosition(
      (position) => this.fill(position.coords),
      (error) => this.fail(error),
      { enableHighAccuracy: true, timeout: 15000, maximumAge: 60000 }
    )
  }

  fill({ latitude, longitude, accuracy }) {
    this.latitudeTarget.value = latitude.toFixed(6)
    this.longitudeTarget.value = longitude.toFixed(6)
    this.accuracyTarget.value = Math.round(accuracy)
    this.show(`Location attached (±${Math.round(accuracy)} m)`)
  }

  fail(error) {
    this.latitudeTarget.value = this.longitudeTarget.value = this.accuracyTarget.value = ""
    const message = error.code === error.PERMISSION_DENIED
      ? "Location blocked. Allow it for this site in your browser settings, or type the address."
      : "Couldn't get a location fix. Retry, or type the address."
    this.show(message)
    this.retryTarget.hidden = false
  }

  show(text) {
    this.statusTarget.textContent = text
  }
}
