class PropertyScore < ApplicationRecord
  belongs_to :property

  enum :compatibility, { non_compatible: 0, partielle: 1, stricte: 2 }

  validates :total_score, numericality: { in: 0..100 }

  def traffic_light
    case total_score
    when 75..100 then :green
    when 45..74 then :orange
    else :red
    end
  end

  def traffic_light_label
    case traffic_light
    when :green then "Compatible"
    when :orange then "Partiellement compatible"
    when :red then "Non compatible"
    end
  end
end
