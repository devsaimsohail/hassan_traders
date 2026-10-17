import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["type", "productOnly", "rateHint"]

  connect() {
    this.update()
  }

  update() {
    const product = this.typeTargets.find((t) => t.checked)?.value === "product"
    this.productOnlyTargets.forEach((el) => {
      el.hidden = !product
      el.querySelectorAll("input").forEach((input) => { input.disabled = !product })
    })
    if (this.hasRateHintTarget) {
      this.rateHintTarget.textContent = (product ? "What one unit costs you to buy or make" : "What you pay the supplier per unit") + ". It becomes the average cost as goods are received."
    }
  }
}
