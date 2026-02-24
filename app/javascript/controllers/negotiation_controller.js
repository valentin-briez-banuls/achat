import { Controller } from "@hotwired/stimulus"

// Negotiation simulator — all calculations run client-side using the standard
// loan amortisation formula (identical to LoanCalculator in Ruby).
// Notary fees are approximated: 7.5% for ancien, 2.5% for neuf.
export default class extends Controller {
  static targets = [
    "discountSlider", "discountDisplay",
    "contribution", "duration",
    // Comparison table — 4 targets each (0%, -3%, -5%, -8%), addressed by index
    "price", "monthly", "debtRatio", "creditCost", "notaryFees",
    // Custom scenario highlight card
    "customDiscountLabel", "customPrice", "customMonthly",
    "customDebtRatio", "customCreditCost", "customNotary",
    // Offer shortcut
    "offerLink", "offerPrice"
  ]

  static values = {
    basePrice: Number,
    rate: Number,
    condition: String,
    income: Number,
    newOfferPath: String
  }

  connect() {
    this._timer = null
    this._updateDiscountDisplay()
    this._recalculate()
  }

  onDiscountChange() {
    this._updateDiscountDisplay()
    this._scheduleRecalculate()
  }

  onChange() {
    this._scheduleRecalculate()
  }

  // ── private ────────────────────────────────────────────────────────────────

  _updateDiscountDisplay() {
    const val = parseFloat(this.discountSliderTarget.value)
    this.discountDisplayTarget.textContent = `${val}%`
  }

  _scheduleRecalculate() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => this._recalculate(), 250)
  }

  _recalculate() {
    const basePrice   = this.basePriceValue
    const rate        = this.rateValue
    const duration    = this._selectedDuration()
    const contribution = parseFloat(this.contributionTarget.value) || 0
    const notaryRate  = this.conditionValue === "ancien" ? 0.075 : 0.025
    const customDiscount = parseFloat(this.discountSliderTarget.value) || 0

    // Fixed comparison columns: 0 %, -3 %, -5 %, -8 %
    ;[0, 3, 5, 8].forEach((discount, idx) => {
      const price = Math.round(basePrice * (1 - discount / 100))
      const d = this._compute(price, rate, duration, contribution, notaryRate)
      this.priceTargets[idx].textContent       = this._fmt(d.price)
      this.monthlyTargets[idx].textContent     = this._fmt(d.monthly)
      this.debtRatioTargets[idx].textContent   = d.debtRatio !== null ? `${d.debtRatio} %` : "—"
      this.creditCostTargets[idx].textContent  = this._fmt(d.creditCost)
      this.notaryFeesTargets[idx].textContent  = this._fmt(d.notaryFees)
    })

    // Custom scenario card
    const customPrice = Math.round(basePrice * (1 - customDiscount / 100))
    const cd = this._compute(customPrice, rate, duration, contribution, notaryRate)

    this.customDiscountLabelTarget.textContent = customDiscount > 0 ? `-${customDiscount} %` : "Prix affiché"
    this.customPriceTarget.textContent         = this._fmt(cd.price)
    this.customMonthlyTarget.textContent       = this._fmt(cd.monthly)
    this.customDebtRatioTarget.textContent     = cd.debtRatio !== null ? `${cd.debtRatio} %` : "—"
    this.customCreditCostTarget.textContent    = this._fmt(cd.creditCost)
    this.customNotaryTarget.textContent        = this._fmt(cd.notaryFees)

    // Offer shortcut link
    this.offerPriceTarget.textContent = this._fmt(customPrice)
    const url = new URL(this.newOfferPathValue, window.location.origin)
    url.searchParams.set("offer[amount]", customPrice)
    this.offerLinkTarget.href = url.pathname + url.search
  }

  _compute(price, rate, duration, contribution, notaryRate) {
    const notaryFees = Math.round(price * notaryRate)
    const loanAmount = Math.max(price + notaryFees - contribution, 0)

    let monthly = 0
    let creditCost = 0

    if (loanAmount > 0 && rate > 0 && duration > 0) {
      const monthlyRate = rate / 100 / 12
      const n = duration * 12
      monthly    = Math.round(loanAmount * monthlyRate / (1 - Math.pow(1 + monthlyRate, -n)))
      creditCost = Math.round(monthly * n - loanAmount)
    }

    const income    = this.incomeValue
    const debtRatio = income > 0 ? Math.round(monthly / income * 1000) / 10 : null

    return { price, notaryFees, loanAmount, monthly, creditCost, debtRatio }
  }

  _selectedDuration() {
    const checked = this.durationTargets.find(r => r.checked)
    return checked ? parseInt(checked.value, 10) : 25
  }

  _fmt(amount) {
    return new Intl.NumberFormat("fr-FR", { maximumFractionDigits: 0 }).format(amount) + " €"
  }
}
