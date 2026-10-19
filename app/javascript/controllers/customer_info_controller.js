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
    this.infoTarget.textContent = `Owes ${data.balance}` + (data.note ? ` · Note: ${data.note}` : "")
    this.infoTarget.hidden = false
  }
}
