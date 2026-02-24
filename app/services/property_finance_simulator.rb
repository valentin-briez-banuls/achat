# Simulation financière complète pour un bien immobilier
# Calcule frais de notaire, PTZ, prêt principal, mensualités, coût total
class PropertyFinanceSimulator
  attr_reader :simulation

  delegate :property, to: :simulation
  delegate :household, to: :property

  def initialize(simulation)
    @simulation = simulation
  end

  def call
    results = compute_all
    simulation.update!(results)
    results
  end

  def compute_all
    notary = compute_notary_fees
    project_cost = compute_total_project_cost(notary)
    ptz = compute_ptz(project_cost)
    main_loan = compute_main_loan(project_cost, ptz)
    monthly = compute_monthly_payments(main_loan, ptz)
    effort = compute_effort(monthly)

    {
      notary_fees: notary[:total],
      total_project_cost: project_cost,
      ptz_eligible: ptz[:eligible],
      ptz_amount: ptz[:max_amount],
      main_loan_amount: main_loan[:principal],
      monthly_payment_main: main_loan[:monthly_payment],
      monthly_payment_ptz: ptz[:monthly_payment],
      total_monthly_payment: monthly[:total],
      total_credit_cost: main_loan[:total_cost] + (ptz[:max_amount] || 0),
      real_monthly_effort: effort[:real_monthly_effort],
      debt_ratio: effort[:debt_ratio]
    }
  end

  private

  def effective_price
    if simulation.negotiated_price&.positive?
      simulation.negotiated_price
    elsif simulation.price_negotiation_percent&.positive?
      property.price * (1 - simulation.price_negotiation_percent / 100)
    else
      property.price
    end
  end

  def compute_notary_fees
    NotaryFeeCalculator.new(
      price: effective_price,
      condition: property.condition
    ).call
  end

  def compute_total_project_cost(notary)
    price = effective_price
    agency = property.agency_fees_included? ? 0 : (property.agency_fees || 0)
    works = simulation.additional_works || property.estimated_works || 0

    (price + agency + notary[:total] + works).round(2)
  end

  def compute_ptz(project_cost)
    profile = household.financial_profile
    return null_ptz unless profile&.ptz_zone.present?

    PTZCalculator.new(
      zone: profile.ptz_zone,
      household_size: profile.household_size,
      fiscal_income: profile.fiscal_reference_income,
      property_type: property.property_type.to_sym,
      operation_cost: effective_price,
      condition: property.condition
    ).call
  end

  def compute_main_loan(project_cost, ptz)
    contribution = simulation.personal_contribution || 0
    ptz_amount = ptz[:eligible] ? ptz[:max_amount] : 0
    principal = project_cost - contribution - ptz_amount
    principal = [principal, 0].max

    calc = LoanCalculator.new(
      principal: principal,
      annual_rate: simulation.loan_rate,
      duration_years: simulation.loan_duration_years
    )

    {
      principal: principal.round(2),
      monthly_payment: calc.monthly_payment,
      total_cost: calc.total_cost
    }
  end

  def compute_monthly_payments(main_loan, ptz)
    ptz_monthly = ptz[:eligible] ? ptz[:monthly_payment] : 0
    { total: (main_loan[:monthly_payment] + ptz_monthly).round(2) }
  end

  def compute_effort(monthly)
    profile = household.financial_profile
    income = profile&.total_monthly_income || 0
    charges = profile&.monthly_charges || 0

    total_charges = monthly[:total] + charges
    debt_ratio = income.positive? ? (total_charges / income * 100).round(2) : 0
    real_effort = (monthly[:total] + (property.copro_charges_monthly || 0) +
                   (property.property_tax_yearly || 0) / 12).round(2)

    { real_monthly_effort: real_effort, debt_ratio: debt_ratio }
  end

  def null_ptz
    { eligible: false, max_amount: 0, monthly_payment: 0 }
  end
end
