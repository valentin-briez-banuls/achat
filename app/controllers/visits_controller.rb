class VisitsController < ApplicationController
  before_action :require_household!
  before_action :set_property
  before_action :set_visit, only: [:edit, :update, :destroy]

  def new
    @visit = @property.visits.build(user: current_user)
    authorize @visit
  end

  def create
    @visit = @property.visits.build(visit_params)
    @visit.user = current_user
    authorize @visit

    if @visit.save
      redirect_to @property, notice: "Visite planifiée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @visit
  end

  def update
    authorize @visit

    if @visit.update(visit_params)
      update_property_status if @visit.effectuee?
      redirect_to @property, notice: "Visite mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @visit
    @visit.destroy
    redirect_to @property, notice: "Visite supprimée."
  end

  private

  def set_property
    @property = current_household.properties.find(params[:property_id])
  end

  def set_visit
    @visit = @property.visits.find(params[:id])
  end

  def visit_params
    params.require(:visit).permit(:scheduled_at, :status, :verdict, :notes, :pros, :cons)
  end

  def update_property_status
    @property.visite! if @property.a_visiter?
  end
end
