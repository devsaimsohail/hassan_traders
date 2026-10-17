import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "info"]

  connect() {
    this.show()
  }

  show() {
    const option = this.selectTarget.selectedOptions[0]
    const data = option?.dataset || {}
    if (!data.balance) {
      this.infoTarget.hidden = true
      return
    }
    const parts = [`Owes ${data.balance}`, `credit limit ${data.limit}`, `pays in ${data.terms} days`]
    this.infoTarget.textContent = parts.join(" · ") + (data.note ? ` · Note: ${data.note}` : "")
    this.infoTarget.classList.toggle("text-bad", data.over === "Yes")
    this.infoTarget.hidden = false
  }
}
