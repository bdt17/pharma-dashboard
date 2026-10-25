import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { apiKey: String, autoRefresh: Boolean }

  connect() {
    console.log("🟢 GPS Map controller connected")
    this.element.innerHTML =
      '<div style="height: 300px; background-color: #eee; display: flex; align-items: center; justify-content: center">' +
      'MAP WILL RENDER HERE (Google Maps / Mapbox goes here)</div>'
  }
}
