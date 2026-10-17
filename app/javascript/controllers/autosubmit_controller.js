import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }

  submitIfValid(event) {
    if (event.target.value && event.target.validity.valid) this.element.requestSubmit()
  }
}
