# Configuration du geocoder
Geocoder.configure(
  # Utiliser Nominatim (OpenStreetMap) comme provider gratuit
  lookup: :nominatim,

  # Timeout
  timeout: 5,

  # Unités
  units: :km,

  # Cache des résultats (utilise le cache Rails)
  cache: Rails.cache,
  cache_prefix: "geocoder:",

  # Headers pour Nominatim (requis)
  http_headers: {
    "User-Agent" => "AchatImmo/1.0 (contact@achat-immo.fr)"
  },

  # Options spécifiques à Nominatim
  nominatim: {
    host: "nominatim.openstreetmap.org",
    email: "contact@achat-immo.fr" # Recommandé par Nominatim
  }
)

