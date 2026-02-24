class PropertyCriteriaController < ApplicationController
  before_action :require_household!
  before_action :set_criterion, only: [:show, :edit, :update]

  def show
    authorize @criterion
  end

  def new
    @criterion = current_household.build_property_criterion
    authorize @criterion
  end

  def create
    @criterion = current_household.build_property_criterion(criterion_params)
    authorize @criterion

    if @criterion.save
      recalculate_all_scores
      redirect_to property_criterion_path, notice: "Critères enregistrés."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @criterion
  end

  def update
    authorize @criterion

    if @criterion.update(criterion_params)
      recalculate_all_scores
      redirect_to property_criterion_path, notice: "Critères mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_criterion
    @criterion = current_household.property_criterion
    redirect_to new_property_criterion_path unless @criterion
  end

  def criterion_params
    params.require(:property_criterion).permit(
      :max_budget, :min_surface, :min_bedrooms,
      :outdoor_required, :parking_required,
      :max_work_distance_km, :geographic_zone,
      :property_condition, :min_energy_class,
      :weight_neighborhood, :weight_view, :weight_orientation,
      :weight_renovation, :weight_quietness, :weight_brightness
    )
  end

  def recalculate_all_scores
    current_household.properties.find_each(&:recalculate_score!)
  end
end
