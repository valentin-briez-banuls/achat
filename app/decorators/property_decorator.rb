class PropertyDecorator < Draper::Decorator
  delegate_all

  def formatted_price
    h.number_to_currency(price, unit: "€", format: "%n %u")
  end

  def formatted_price_per_sqm
    h.number_to_currency(price_per_sqm, unit: "€/m²", format: "%n %u")
  end

  def formatted_surface
    "#{surface} m²"
  end

  def status_badge
    colors = {
      "a_analyser" => "bg-gray-100 text-gray-800",
      "a_visiter" => "bg-blue-100 text-blue-800",
      "visite" => "bg-purple-100 text-purple-800",
      "offre_faite" => "bg-yellow-100 text-yellow-800",
      "refuse" => "bg-red-100 text-red-800",
      "accepte" => "bg-green-100 text-green-800"
    }
    labels = {
      "a_analyser" => "À analyser",
      "a_visiter" => "À visiter",
      "visite" => "Visité",
      "offre_faite" => "Offre faite",
      "refuse" => "Refusé",
      "accepte" => "Accepté"
    }
    css = colors[status] || "bg-gray-100 text-gray-800"
    label = labels[status] || status
    h.content_tag(:span, label, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{css}")
  end

  def energy_badge
    return "—" unless energy_class.present?
    colors = {
      "A" => "bg-green-600", "B" => "bg-green-500", "C" => "bg-yellow-400",
      "D" => "bg-yellow-500", "E" => "bg-orange-500", "F" => "bg-red-500", "G" => "bg-red-700"
    }
    css = colors[energy_class] || "bg-gray-400"
    h.content_tag(:span, "DPE #{energy_class}", class: "inline-flex items-center px-2 py-1 rounded text-xs font-bold text-white #{css}")
  end

  def score_badge
    return "—" unless property_score
    score = property_score.total_score
    color = case score
            when 75..100 then "bg-green-100 text-green-800 border-green-300"
            when 45..74 then "bg-yellow-100 text-yellow-800 border-yellow-300"
            else "bg-red-100 text-red-800 border-red-300"
            end
    h.content_tag(:span, "#{score}/100", class: "inline-flex items-center px-2.5 py-1 rounded-lg text-sm font-bold border #{color}")
  end

  def type_label
    { "appartement" => "Appartement", "maison" => "Maison", "terrain" => "Terrain",
      "loft" => "Loft", "duplex" => "Duplex" }[property_type] || property_type
  end

  def condition_label
    { "ancien" => "Ancien", "neuf" => "Neuf" }[condition] || condition
  end

  def location
    "#{city} (#{postal_code})"
  end
end
