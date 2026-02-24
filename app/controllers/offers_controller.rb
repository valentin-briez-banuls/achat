class OffersController < ApplicationController
  before_action :require_household!
  before_action :set_property
  before_action :set_offer, only: [:edit, :update, :destroy]

  def new
    @offer = @property.offers.build(
      offered_on: Date.current,
      amount: @property.price
    )
    authorize @offer
  end

  def create
    @offer = @property.offers.build(offer_params)
    authorize @offer

    if @offer.save
      @property.offre_faite! unless @property.offre_faite? || @property.accepte?
      redirect_to @property, notice: "Offre enregistrée."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @offer
  end

  def update
    authorize @offer

    if @offer.update(offer_params)
      update_property_status
      redirect_to @property, notice: "Offre mise à jour."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @offer
    @offer.destroy
    redirect_to @property, notice: "Offre supprimée."
  end

  private

  def set_property
    @property = current_household.properties.find(params[:property_id])
  end

  def set_offer
    @offer = @property.offers.find(params[:id])
  end

  def offer_params
    params.require(:offer).permit(
      :amount, :offered_on, :response_deadline,
      :status, :conditions, :notes, :counter_offer_amount
    )
  end

  def update_property_status
    if @offer.acceptee?
      @property.accepte!
    elsif @offer.refusee?
      @property.refuse! unless @property.offers.en_attente.exists?
    end
  end
end
