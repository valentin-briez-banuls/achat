class ComparisonsController < ApplicationController
  before_action :require_household!

  def show
    skip_authorization

    property_ids = params[:property_ids]&.reject(&:blank?) || []

    if property_ids.size < 2
      redirect_to properties_path, alert: "Sélectionnez au moins 2 biens à comparer."
      return
    end

    @properties = current_household.properties
      .where(id: property_ids.first(4))
      .includes(:property_score, :simulations)

    @simulations = @properties.map do |prop|
      [ prop, prop.simulations.order(:created_at).last ]
    end.to_h

    @scores = @properties.map do |prop|
      [ prop, prop.property_score ]
    end.to_h
  end
end
