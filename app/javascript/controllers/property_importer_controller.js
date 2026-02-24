import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["urlInput", "importButton", "status", "form"]
  static values = { importUrl: String }

  connect() {
    console.log("PropertyImporter controller connected")
  }

  async importFromUrl(event) {
    event.preventDefault()

    const url = this.urlInputTarget.value.trim()

    if (!url) {
      this.showError("Veuillez entrer une URL")
      return
    }

    this.showLoading()

    try {
      const response = await fetch(this.importUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({ url })
      })

      const data = await response.json()

      if (response.ok && data.success) {
        this.fillForm(data.data)

        // Afficher un message avec les infos sur les images
        let successMessage = "Données importées avec succès !"
        if (data.images_count > 0) {
          successMessage += ` (${data.images_count} photo${data.images_count > 1 ? 's' : ''} trouvée${data.images_count > 1 ? 's' : ''})`
        }

        this.showSuccess(successMessage, data.images_count)
      } else {
        this.showError(data.error || "Erreur lors de l'import")
      }
    } catch (error) {
      console.error("Import error:", error)
      this.showError("Erreur réseau ou serveur")
    }
  }

  fillForm(data) {
    // Remplir tous les champs du formulaire avec les données extraites
    Object.entries(data).forEach(([key, value]) => {
      if (value == null) return

      const input = this.formTarget.querySelector(`[name="property[${key}]"]`)

      if (input) {
        if (input.type === "checkbox") {
          input.checked = value
        } else {
          input.value = value
        }

        // Déclencher un événement change pour mettre à jour l'UI si nécessaire
        input.dispatchEvent(new Event("change", { bubbles: true }))
      }
    })

    // Scroll vers le haut du formulaire
    this.formTarget.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  showLoading() {
    this.importButtonTarget.disabled = true
    this.importButtonTarget.textContent = "Import en cours..."
    this.statusTarget.innerHTML = `
      <div class="flex items-center gap-2 text-blue-600">
        <svg class="animate-spin h-4 w-4" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        <span>Extraction des données en cours...</span>
      </div>
    `
    this.statusTarget.classList.remove("hidden")
  }

  showSuccess(message, imagesCount = 0) {
    this.importButtonTarget.disabled = false
    this.importButtonTarget.textContent = "Importer depuis l'URL"

    const imageIcon = imagesCount > 0 ? `
      <svg class="h-5 w-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z" />
      </svg>
    ` : ''

    this.statusTarget.innerHTML = `
      <div class="flex items-center gap-2 text-green-600">
        <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        ${imageIcon}
        <span>${message}</span>
      </div>
    `

    // Masquer le message après 5 secondes
    setTimeout(() => {
      this.statusTarget.classList.add("hidden")
    }, 5000)
  }

  showError(message) {
    this.importButtonTarget.disabled = false
    this.importButtonTarget.textContent = "Importer depuis l'URL"
    this.statusTarget.innerHTML = `
      <div class="flex items-center gap-2 text-red-600">
        <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
        </svg>
        <span>${message}</span>
      </div>
    `

    // Masquer le message après 8 secondes
    setTimeout(() => {
      this.statusTarget.classList.add("hidden")
    }, 8000)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content || ""
  }
}

