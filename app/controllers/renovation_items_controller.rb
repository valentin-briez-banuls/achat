class RenovationItemsController < ApplicationController
  before_action :require_household!
  before_action :set_property
  before_action :set_renovation_item, only: [:edit, :update, :destroy]

  def new
    @renovation_item = @property.renovation_items.build
    authorize @renovation_item
  end

  def create
    @renovation_item = @property.renovation_items.build(renovation_item_params)
    authorize @renovation_item

    if @renovation_item.save
      redirect_to @property, notice: "Poste de travaux ajouté."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @renovation_item
  end

  def update
    authorize @renovation_item

    if @renovation_item.update(renovation_item_params)
      redirect_to @property, notice: "Poste de travaux mis à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @renovation_item
    @renovation_item.destroy
    redirect_to @property, notice: "Poste de travaux supprimé."
  end

  private

  def set_property
    @property = current_household.properties.find(params[:property_id])
  end

  def set_renovation_item
    @renovation_item = @property.renovation_items.find(params[:id])
  end

  def renovation_item_params
    params.require(:renovation_item).permit(:category, :description, :estimated_cost_min, :estimated_cost_max)
  end
end
