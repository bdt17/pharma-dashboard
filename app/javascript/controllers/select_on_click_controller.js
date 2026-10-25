import { Controller } from "@hotwired/stimulus"

// Selects a read-only field's contents on click, for copy-paste snippets.
// Replaces an inline onclick="this.select()", which the Content Security
// Policy blocks.
export default class extends Controller {
  select() {
    this.element.select()
  }
}
