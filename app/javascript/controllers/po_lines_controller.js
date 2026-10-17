import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["lines", "template", "total"]

  connect() {
    this.recalc()
  }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll("NEW_LINE", Date.now().toString())
    this.linesTarget.insertAdjacentHTML("beforeend", html)
  }

  remove(event) {
    const line = event.target.closest("[data-line]")
    const destroy = line.querySelector("input[name$='[_destroy]']")
    if (destroy) {
      destroy.value = "1"
      line.hidden = true
    } else {
      line.remove()
    }
    this.recalc()
  }

  pickItem(event) {
    const option = event.target.selectedOptions[0]
    const line = event.target.closest("[data-line]")
    const rate = line.querySelector("[data-field=rate]")
    if (option?.dataset.rate && !rate.value) rate.value = option.dataset.rate
    line.querySelector("[data-field=unit]").textContent = option?.dataset.unit || ""
    this.recalc()
  }

  recalc() {
    const format = new Intl.NumberFormat("en-IN", { maximumFractionDigits: 0 })
    let total = 0
    this.linesTarget.querySelectorAll("[data-line]:not([hidden])").forEach((line) => {
      const qty = parseFloat(line.querySelector("[data-field=qty]").value) || 0
      const rate = parseFloat(line.querySelector("[data-field=rate]").value) || 0
      const amount = Math.round(qty * rate)
      total += amount
      line.querySelector("[data-field=amount]").textContent = `Rs ${format.format(amount)}`
    })
    this.totalTarget.textContent = `Rs ${format.format(total)}`
  }
}
