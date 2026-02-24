class SimulationsController < ApplicationController
  before_action :require_household!
  before_action :set_property
  before_action :set_simulation, only: [:show, :edit, :update, :destroy]

  def index
    @simulations = policy_scope(Simulation)
      .where(property: @property)
      .order(:created_at)
  end

  def show
    authorize @simulation
    @property = @simulation.property
    profile = current_household.financial_profile

    if profile&.proposed_rate
      @rate_impact = LoanCalculator.rate_impact(
        principal: @simulation.main_loan_amount || 0,
        duration_years: @simulation.loan_duration_years,
        base_rate: @simulation.loan_rate
      )
    end
  end

  def new
    profile = current_household.financial_profile
    @simulation = @property.simulations.build(
      loan_rate: profile&.proposed_rate || 3.5,
      loan_duration_years: profile&.desired_duration_years || 25,
      personal_contribution: profile&.personal_contribution || 0,
      negotiated_price: @property.price,
      scenario: :standard
    )
    authorize @simulation
  end

  def create
    @simulation = @property.simulations.build(simulation_params)
    authorize @simulation

    if @simulation.save
      @simulation.recalculate!
      redirect_to property_simulation_path(@property, @simulation), notice: "Simulation créée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @simulation
  end

  def update
    authorize @simulation

    if @simulation.update(simulation_params)
      @simulation.recalculate!
      redirect_to property_simulation_path(@property, @simulation), notice: "Simulation mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @simulation
    @simulation.destroy
    redirect_to property_simulations_path(@property), notice: "Simulation supprimée."
  end

  private

  def set_property
    @property = current_household.properties.find(params[:property_id])
  end

  def set_simulation
    @simulation = @property.simulations.find(params[:id])
  end

  def simulation_params
    params.require(:simulation).permit(
      :name, :scenario, :loan_rate, :loan_duration_years,
      :personal_contribution, :negotiated_price,
      :additional_works, :price_negotiation_percent
    )
  end
end
