class PropertiesController < ApplicationController
  before_action :require_household!
  before_action :set_property, only: [:show, :edit, :update, :destroy]

  def index
    properties = policy_scope(Property)
      .includes(:property_score)

    # Filtre par statut
    properties = properties.with_status(params[:status]) if params[:status].present?

    # Filtre par type de bien
    properties = properties.where(property_type: params[:property_type]) if params[:property_type].present?

    # Filtre par ville (recherche partielle, insensible à la casse)
    properties = properties.where("city ILIKE ?", "%#{params[:city]}%") if params[:city].present?

    # Filtre par prix
    properties = properties.where("price >= ?", params[:min_price]) if params[:min_price].present?
    properties = properties.where("price <= ?", params[:max_price]) if params[:max_price].present?

    # Filtre par surface
    properties = properties.where("surface >= ?", params[:min_surface]) if params[:min_surface].present?
    properties = properties.where("surface <= ?", params[:max_surface]) if params[:max_surface].present?

    # Filtre par nombre de chambres
    properties = properties.where("bedrooms >= ?", params[:min_bedrooms]) if params[:min_bedrooms].present?

    # Filtre par classe énergie (DPE max = on accepte toutes les classes <= celle choisie)
    if params[:energy_class].present?
      allowed = Property::ENERGY_CLASSES[0..Property::ENERGY_CLASSES.index(params[:energy_class])]
      properties = properties.where(energy_class: allowed)
    end

    # Tri
    properties = case params[:sort]
                 when "price_asc"    then properties.order(price: :asc)
                 when "price_desc"   then properties.order(price: :desc)
                 when "surface_desc" then properties.order(surface: :desc)
                 when "score_desc"   then properties.left_joins(:property_score).order("property_scores.total_score DESC NULLS LAST")
                 else properties.order(created_at: :desc)
                 end

    # TODO: Réactiver pagy une fois le module configuré pour Pagy 9+
    # @pagy, @properties = pagy(properties, items: 12)
    @properties = properties.limit(50)
  end

  def show
    authorize @property
    @score = @property.property_score
    @simulations = @property.simulations.order(:created_at)
    @visits = @property.visits.order(scheduled_at: :desc)
    @offers = @property.offers.order(offered_on: :desc)
    @notary_fees = NotaryFeeCalculator.new(price: @property.effective_price, condition: @property.condition).call
    @price_history = @property.price_histories.order(:scraped_at)
  end

  def new
    @property = current_household.properties.build
    authorize @property
  end

  def import_from_url
    authorize Property.new(household: current_household)

    raw_url = params[:url]

    if raw_url.blank?
      render json: { error: "URL manquante" }, status: :unprocessable_entity
      return
    end

    # Nettoyer l'URL (gérer les liens Markdown, espaces, etc.)
    url = clean_url(raw_url)

    Rails.logger.info("=== PropertyScraperService: Starting scrape for URL: #{url}")

    # Options de scraping
    options = {
      cache: params[:no_cache] != "true", # Permettre de forcer le bypass du cache
      images: true,
      geocode: true,
      javascript: params[:javascript] == "true" # Peut être activé via un paramètre
    }

    scraper = PropertyScraperService.new(url, options)
    property_data = scraper.call

    Rails.logger.info("=== PropertyScraperService: Result: #{property_data.inspect}")
    Rails.logger.info("=== PropertyScraperService: Images found: #{scraper.image_urls.size}")
    Rails.logger.info("=== PropertyScraperService: Errors: #{scraper.errors.inspect}")

    if property_data
      response_data = {
        success: true,
        data: property_data.merge(image_urls: scraper.image_urls.to_json),  # Ajouter les URLs en JSON
        image_urls: scraper.image_urls,
        images_count: scraper.image_urls.size,
        warnings: scraper.errors # Inclure les warnings même en cas de succès
      }
      render json: response_data
    else
      error_message = scraper.errors.any? ? scraper.errors.join(", ") : "Impossible d'extraire les données"
      Rails.logger.error("=== PropertyScraperService: Failed with error: #{error_message}")
      render json: { error: error_message }, status: :unprocessable_entity
    end
  end

  def create
    @property = current_household.properties.build(property_params)
    authorize @property

    if @property.save
      @property.record_price_history!(source: "manual")
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
      @property.record_price_history!(source: "manual")
      @property.recalculate_score!
      DownloadPropertyImagesJob.perform_later(@property.id) if @property.parsed_image_urls.any?
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

  def clean_url(raw_url)
    # Supprimer les espaces avant et après
    url = raw_url.strip

    # Gérer les liens Markdown [texte](url)
    if url =~ /\[.*?\]\((https?:\/\/[^\)]+)\)/
      url = $1
    end

    # Gérer les liens entre chevrons <url>
    if url =~ /<(https?:\/\/.+)>/
      url = $1
    end

    # Décoder les URLs encodées (si nécessaire)
    url = URI.decode_www_form_component(url) if url.include?('%')

    url
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
      :status, :listing_url, :personal_notes, :image_urls,
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
