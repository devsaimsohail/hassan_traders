import { Controller } from "@hotwired/stimulus"
import "tom-select"

// Turns a <select> into a Select2-style dropdown (Tom Select), with a search box when the
// list is long. The original select stays in the form, keeps its options' data-* attributes
// and still gets "change" events, so other controllers and autosubmit keep working.
export default class extends Controller {
  static SEARCH_FROM = 8

  connect() {
    const searchable = this.element.options.length >= this.constructor.SEARCH_FROM
    const settings = { allowEmptyOption: true, maxOptions: null, dropdownParent: "body",
      render: { no_results: () => '<div class="no-results">Nothing matches</div>' } }
    if (searchable) settings.plugins = ["dropdown_input"]
    else settings.controlInput = null

    this.tomSelect = new window.TomSelect(this.element, settings)
    if (searchable) this.tomSelect.control_input.placeholder = "Type to search…"

    // Tom Select lines the dropdown up with its inner control; line it up with the whole box.
    this.tomSelect.positionDropdown = () => {
      const box = this.tomSelect.wrapper.getBoundingClientRect()
      Object.assign(this.tomSelect.dropdown.style, {
        top: `${box.bottom + window.scrollY}px`, left: `${box.left + window.scrollX}px`, width: `${box.width}px`
      })
    }

    // Turbo caches a copy of the page; put the plain select back first so the copy can be re-enhanced.
    this.teardown = () => this.destroy()
    document.addEventListener("turbo:before-cache", this.teardown)
  }

  disconnect() {
    document.removeEventListener("turbo:before-cache", this.teardown)
    this.destroy()
  }

  destroy() {
    this.tomSelect?.destroy()
    this.tomSelect = null
  }
}
