import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rate", "duration", "contribution", "price", "negotiation", "negotiationDisplay", "estimate"]

  updateNegotiation() {
    const val = this.negotiationTarget.value
    this.negotiationDisplayTarget.textContent = `${val}%`
  }

  calculate() {
    // Client-side estimate (approximate, server does the real calculation)
    const rate = parseFloat(this.rateTarget.value) || 3.5
    const duration = parseInt(this.durationTarget.value) || 25
    const contribution = parseFloat(this.contributionTarget.value) || 0
    const price = parseFloat(this.priceTarget.value) || 0

    if (price <= 0 || rate <= 0) return

    // Rough notary fees estimate (7.5% for ancien)
    const notaryFees = price * 0.075
    const totalCost = price + notaryFees
    const principal = Math.max(totalCost - contribution, 0)

    // Monthly payment formula
    const monthlyRate = rate / 100 / 12
    const numPayments = duration * 12
    const monthly = principal * monthlyRate / (1 - Math.pow(1 + monthlyRate, -numPayments))

    this.estimateTarget.innerHTML = `
      <div class="grid grid-cols-2 gap-2 text-sm">
        <div><span class="text-blue-600 font-medium">Estimation mensualité :</span></div>
        <div class="text-right font-bold text-blue-800">${Math.round(monthly).toLocaleString('fr-FR')} €/mois</div>
        <div><span class="text-gray-600">Montant emprunté :</span></div>
        <div class="text-right font-medium">${Math.round(principal).toLocaleString('fr-FR')} €</div>
        <div><span class="text-gray-600">Coût total crédit :</span></div>
        <div class="text-right font-medium">${Math.round(monthly * numPayments).toLocaleString('fr-FR')} €</div>
      </div>
      <p class="mt-2 text-xs text-blue-500">Estimation indicative — le calcul précis sera fait côté serveur.</p>
    `
  }
}
