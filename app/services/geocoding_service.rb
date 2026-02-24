class GeocodingService
  attr_reader :errors

  def initialize(city, postal_code, address = nil)
    @city = city
    @postal_code = postal_code
    @address = address
    @errors = []
  end

  def call
    return nil unless valid_inputs?

    coordinates = geocode_address
    return nil unless coordinates

    {
      latitude: coordinates[0],
      longitude: coordinates[1]
    }
  rescue StandardError => e
    @errors << "Erreur de géocoding : #{e.message}"
    Rails.logger.error("GeocodingService error: #{e.message}\n#{e.backtrace.join("\n")}")
    nil
  end

  private

  def valid_inputs?
    if @city.blank? || @postal_code.blank?
      @errors << "Ville et code postal requis pour le géocoding"
      return false
    end

    unless @postal_code.match?(/\A\d{5}\z/)
      @errors << "Code postal invalide"
      return false
    end

    true
  end

  def geocode_address
    # Construire la requête de géocoding
    query_parts = []
    query_parts << @address if @address.present?
    query_parts << @postal_code
    query_parts << @city
    query_parts << "France"

    query = query_parts.join(", ")

    Rails.logger.info("GeocodingService: Geocoding '#{query}'")

    # Faire la requête de géocoding
    results = Geocoder.search(query)

    if results.empty?
      # Essayer avec moins de détails si la première recherche échoue
      simple_query = "#{@postal_code} #{@city}, France"
      Rails.logger.info("GeocodingService: Retry with '#{simple_query}'")
      results = Geocoder.search(simple_query)
    end

    if results.empty?
      @errors << "Aucune coordonnée trouvée pour cette adresse"
      return nil
    end

    result = results.first
    coordinates = result.coordinates

    Rails.logger.info("GeocodingService: Found coordinates #{coordinates.inspect}")
    coordinates
  end
end

