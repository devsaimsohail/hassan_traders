import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker", "swatch", "logo", "preview", "remove"]

  pick(event) {
    this.apply(event.currentTarget.value)
  }

  apply(color) {
    if (!/^#[0-9a-f]{6}$/i.test(color)) return
    this.pickerTarget.value = color
    this.swatchTargets.forEach((s) => { s.checked = s.value.toLowerCase() === color.toLowerCase() })
    const root = document.documentElement
    root.style.setProperty("--brand", color)
    root.style.setProperty("--brand-ink", this.luminance(color) > 0.4 ? "#111111" : "#FFFFFF")
  }

  previewLogo() {
    const file = this.logoTarget.files[0]
    if (!file) return
    if (this.hasRemoveTarget) this.removeTarget.checked = false
    const img = document.createElement("img")
    img.alt = "New logo"
    img.className = "size-14 rounded-xl bg-white object-contain"
    img.src = URL.createObjectURL(file)
    this.previewTarget.replaceChildren(img)
  }

  luminance(hex) {
    const [r, g, b] = [1, 3, 5].map((i) => {
      const v = parseInt(hex.slice(i, i + 2), 16) / 255
      return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4
    })
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
  }
}
