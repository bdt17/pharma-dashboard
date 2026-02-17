import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { refreshInterval: Number }

  connect() {
    console.log("🔵 FDA Audit Trail controller connected")
    this.startPolling()
  }

  startPolling() {
    const ms = this.refreshIntervalValue || 10000
    setInterval(async () => {
      try {
        const response = await fetch("/compliance")
        const html = await response.text()

        const doc = new DOMParser().parseFromString(html, "text/html")
        const newList = doc.querySelector("ul[data-controller='fda-audit-trail']")

        if (newList) {
          const ul = this.element.closest("ul")
          ul.innerHTML = ""
          newList.childNodes.forEach(child => ul.appendChild(child.cloneNode(true)))
        }
      } catch (error) {
        console.error("Error fetching compliance logs:", error)
      }
    }, ms)
  }
}
