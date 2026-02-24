import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  validate(event) {
    const checked = document.querySelectorAll('input[name="property_ids[]"]:checked')

    if (checked.length < 2) {
      event.preventDefault()
      alert("Sélectionnez au moins 2 biens à comparer.")
    }
  }
}
