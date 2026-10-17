import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { href: String }

  open(event) {
    if (event.target.closest("a, button, input, select, label")) return
    if (window.getSelection().toString()) return
    Turbo.visit(this.hrefValue)
  }
}
