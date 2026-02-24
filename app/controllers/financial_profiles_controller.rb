class FinancialProfilesController < ApplicationController
  before_action :require_household!
  before_action :set_financial_profile, only: [:show, :edit, :update]

  def show
    authorize @financial_profile
    @calculator = FinancialProfileCalculator.new(@financial_profile)
    @finance_data = @calculator.call

    if @financial_profile.proposed_rate
      @rate_impact = LoanCalculator.rate_impact(
        principal: @finance_data[:borrowing_capacity],
        duration_years: @financial_profile.desired_duration_years,
        base_rate: @financial_profile.proposed_rate
      )
    end
  end

  def new
    @financial_profile = current_household.build_financial_profile
    authorize @financial_profile
  end

  def create
    @financial_profile = current_household.build_financial_profile(financial_profile_params)
    authorize @financial_profile

    if @financial_profile.save
      @financial_profile.recalculate!
      redirect_to financial_profile_path, notice: "Profil financier créé."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @financial_profile
  end

  def update
    authorize @financial_profile

    if @financial_profile.update(financial_profile_params)
      @financial_profile.recalculate!
      redirect_to financial_profile_path, notice: "Profil financier mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_financial_profile
    @financial_profile = current_household.financial_profile
    redirect_to new_financial_profile_path unless @financial_profile
  end

  def financial_profile_params
    params.require(:financial_profile).permit(
      :salary_person_1, :salary_person_2, :other_income,
      :monthly_charges, :personal_contribution, :remaining_savings,
      :contract_type_person_1, :contract_type_person_2,
      :proposed_rate, :desired_duration_years,
      :fiscal_reference_income, :household_size, :ptz_zone
    )
  end
end
