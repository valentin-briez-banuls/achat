class PropertiesController < ApplicationController
  before_action :require_household!
  before_action :set_property, only: [:show, :edit, :update, :destroy]

  def index
    properties = policy_scope(Property)
      .includes(:property_score)

    properties = properties.with_status(params[:status]) if params[:status].present?

    @pagy, @properties = pagy(properties.order(created_at: :desc), items: 12)
  end

  def show
    authorize @property
    @score = @property.property_score
    @simulations = @property.simulations.order(:created_at)
    @visits = @property.visits.order(scheduled_at: :desc)
    @offers = @property.offers.order(offered_on: :desc)
  end

  def new
    @property = current_household.properties.build
    authorize @property
  end

  def create
    @property = current_household.properties.build(property_params)
    authorize @property

    if @property.save
      @property.recalculate_score!
      create_default_simulation
      redirect_to @property, notice: "Bien ajouté avec succès."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @property
  end

  def update
    authorize @property

    if @property.update(property_params)
      @property.recalculate_score!
      redirect_to @property, notice: "Bien mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @property
    @property.destroy
    redirect_to properties_path, notice: "Bien supprimé."
  end

  private

  def set_property
    @property = current_household.properties.find(params[:id])
  end

  def property_params
    params.require(:property).permit(
      :title, :price, :surface, :property_type, :rooms, :bedrooms,
      :city, :postal_code, :address, :latitude, :longitude,
      :agency_fees, :agency_fees_included, :notary_fees_estimate,
      :copro_charges_monthly, :property_tax_yearly, :estimated_works,
      :energy_class, :ges_class, :condition, :has_outdoor, :has_parking,
      :floor, :total_floors,
      :score_neighborhood, :score_view, :score_orientation,
      :score_renovation, :score_quietness, :score_brightness,
      :status, :listing_url, :personal_notes,
      photos: []
    )
  end

  def create_default_simulation
    profile = current_household.financial_profile
    return unless profile

    @property.simulations.create!(
      name: "Simulation initiale",
      scenario: :standard,
      loan_rate: profile.proposed_rate || 3.5,
      loan_duration_years: profile.desired_duration_years || 25,
      personal_contribution: profile.personal_contribution || 0,
      negotiated_price: @property.price
    ).recalculate!
  end
end
