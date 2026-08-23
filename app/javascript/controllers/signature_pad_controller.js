import { Controller } from "@hotwired/stimulus"
import SignaturePad from "signature_pad"

// Draws a signature onto a canvas and serializes it into a hidden form
// field as a base64 PNG data URL on submit. No server round-trip until the
// form is actually submitted -- the drawing itself is entirely client-side.
export default class extends Controller {
  static targets = ["canvas", "input", "clearButton"]

  connect() {
    this.pad = new SignaturePad(this.canvasTarget)
    this.resizeCanvas()
    this.resizeHandler = () => this.resizeCanvas()
    window.addEventListener("resize", this.resizeHandler)
  }

  disconnect() {
    window.removeEventListener("resize", this.resizeHandler)
    this.pad?.off()
  }

  // Canvas pixel dimensions have to match its displayed size (accounting
  // for device pixel ratio) or SignaturePad's coordinates drift from where
  // the pointer actually is -- standard fix from the library's own docs.
  resizeCanvas() {
    const ratio = Math.max(window.devicePixelRatio || 1, 1)
    const canvas = this.canvasTarget
    canvas.width = canvas.offsetWidth * ratio
    canvas.height = canvas.offsetHeight * ratio
    canvas.getContext("2d").scale(ratio, ratio)
    this.pad?.clear()
  }

  clear() {
    this.pad.clear()
    this.inputTarget.value = ""
  }

  // Called on the form's submit event (data-action="submit->signature-pad#save")
  // so the hidden field is populated right before the request goes out.
  save() {
    this.inputTarget.value = this.pad.isEmpty() ? "" : this.pad.toDataURL("image/png")
  }
}
