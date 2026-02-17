import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { refreshInterval: Number }

  connect() {
    console.log("🟡 Batch Live Table controller connected")
    this.startPolling()
  }

  startPolling() {
    const ms = this.refreshIntervalValue || 5000
    setInterval(async () => {
      try {
        const response = await fetch("/batches")
        const html = await response.text()

        const doc = new DOMParser().parseFromString(html, "text/html")
        const newBody = doc.querySelector("#batch-table-body")

        if (newBody) {
          const tbody = this.element.querySelector("#batch-table-body")
          tbody.innerHTML = newBody.innerHTML
        }
      } catch (error) {
        console.error("Error fetching batches:", error)
      }
    }, ms)
  }
}
