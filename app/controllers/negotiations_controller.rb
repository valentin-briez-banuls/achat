class NegotiationsController < ApplicationController
  before_action :require_household!
  before_action :set_property
  skip_after_action :verify_authorized

  def show
    @profile = current_household.financial_profile
    @rate    = @profile&.proposed_rate || 3.5
    @duration    = @profile&.desired_duration_years || 25
    @contribution = (@profile&.personal_contribution || 0).to_i
  end

  def calculate
    rate         = params[:rate].to_d
    duration     = params[:duration].to_i
    contribution = params[:contribution].to_d
    prices       = Array(params[:prices]).map(&:to_d).select(&:positive?)

    if prices.empty? || rate <= 0 || duration.zero?
      return render json: { error: "Paramètres invalides" }, status: :bad_request
    end

    income   = current_household.financial_profile&.total_monthly_income.to_f
    condition = @property.condition

    scenarios = prices.map { |price| compute_scenario(price, rate, duration, contribution, condition, income) }

    render json: { scenarios: scenarios }
  end

  private

  def set_property
    @property = current_household.properties.find(params[:property_id])
  end

  def compute_scenario(price, rate, duration, contribution, condition, income)
    notary       = NotaryFeeCalculator.new(price: price, condition: condition)
    notary_total = notary.total
    loan_amount  = [price + notary_total - contribution, 0].max

    if loan_amount.positive?
      loan        = LoanCalculator.new(principal: loan_amount, annual_rate: rate, duration_years: duration)
      monthly     = loan.monthly_payment.to_f.round
      credit_cost = loan.total_interest.to_f.round
    else
      monthly     = 0
      credit_cost = 0
    end

    debt_ratio = income > 0 ? (monthly.to_f / income * 100).round(1) : nil

    {
      purchase_price: price.to_f.round,
      monthly_payment: monthly,
      debt_ratio: debt_ratio,
      total_credit_cost: credit_cost,
      notary_fees: notary_total.to_f.round,
      loan_amount: loan_amount.to_f.round
    }
  end
end
