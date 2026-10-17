import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["customer", "against", "amount", "info", "ref"]

  connect() {
    this.filter(false)
  }

  customerChanged() {
    this.filter(true)
  }

  filter(pickFirst) {
    const customer = this.customerTarget.value
    const options = Array.from(this.againstTarget.options)
    options.forEach((o) => {
      const show = !o.dataset.customer || o.dataset.customer === customer
      o.hidden = !show
      o.disabled = !show
    })
    if (pickFirst || this.againstTarget.selectedOptions[0]?.disabled) {
      const first = options.find((o) => !o.disabled && o.dataset.customer) || options.find((o) => !o.disabled)
      if (first) first.selected = true
      this.againstChanged()
    }
    const data = this.customerTarget.selectedOptions[0]?.dataset || {}
    this.infoTarget.textContent = data.balance ? `Owes ${data.balance} in total · ${data.bills} unpaid bills, oldest first` : ""
  }

  againstChanged() {
    const due = this.againstTarget.selectedOptions[0]?.dataset.due
    if (due) this.amountTarget.value = due
  }

  methodChanged(event) {
    this.refTarget.required = event.target.value !== "cash"
  }
}
