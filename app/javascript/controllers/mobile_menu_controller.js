import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer", "overlay"]

  open() {
    this.drawerTarget.classList.remove("-translate-x-full")
    this.drawerTarget.classList.add("translate-x-0")
    this.overlayTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.element.querySelector("[data-mobile-menu-button]")?.setAttribute("aria-expanded", "true")
  }

  close() {
    this.drawerTarget.classList.add("-translate-x-full")
    this.drawerTarget.classList.remove("translate-x-0")
    this.overlayTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    this.element.querySelector("[data-mobile-menu-button]")?.setAttribute("aria-expanded", "false")
  }
}

