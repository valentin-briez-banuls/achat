class DashboardController < ApplicationController
  before_action :require_household!

  def show
    skip_authorization

    @financial_profile = current_household.financial_profile
    @criteria = current_household.property_criterion
    @properties = current_household.properties.includes(:property_score).by_score.limit(10)
    @price_drops_count = current_household.properties.includes(:price_histories).count(&:price_dropped?)
    @upcoming_visits = Visit.joins(:property)
                            .where(properties: { household_id: current_household.id })
                            .upcoming.limit(5)
    @pending_offers = Offer.joins(:property)
                           .where(properties: { household_id: current_household.id })
                           .pending.recent.limit(5)

    if @financial_profile
      @calculator = FinancialProfileCalculator.new(@financial_profile)
      @finance_data = @calculator.call
    end

    # Données pour graphiques
    @monthly_payments_data = build_monthly_payments_chart
    @debt_ratio_data = build_debt_ratio_chart
    @scores_data = build_scores_chart
  end

  private

  def build_monthly_payments_chart
    current_household.properties
      .includes(:simulations)
      .where.not(simulations: { id: nil })
      .map do |prop|
        sim = prop.simulations.order(:created_at).last
        [prop.title.truncate(25), sim.total_monthly_payment.to_f] if sim
      end.compact
  end

  def build_debt_ratio_chart
    current_household.properties
      .includes(:simulations)
      .where.not(simulations: { id: nil })
      .map do |prop|
        sim = prop.simulations.order(:created_at).last
        [prop.title.truncate(25), sim.debt_ratio.to_f] if sim
      end.compact
  end

  def build_scores_chart
    current_household.properties
      .includes(:property_score)
      .where.not(property_scores: { id: nil })
      .map { |prop| [prop.title.truncate(25), prop.property_score.total_score] }
  end
end
