import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    const form = document.getElementById("compare-form")
    const checked = form.querySelectorAll('input[name="property_ids[]"]:checked')

    if (checked.length < 2) {
      event.preventDefault()
      alert("Sélectionnez au moins 2 biens à comparer.")
    }
  }
}
