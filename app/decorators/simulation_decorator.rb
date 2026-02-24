class SimulationDecorator < Draper::Decorator
  delegate_all

  def formatted_total_monthly
    h.number_to_currency(total_monthly_payment, unit: "€", format: "%n %u")
  end

  def formatted_total_project_cost
    h.number_to_currency(total_project_cost, unit: "€", format: "%n %u")
  end

  def formatted_total_credit_cost
    h.number_to_currency(total_credit_cost, unit: "€", format: "%n %u")
  end

  def formatted_notary_fees
    h.number_to_currency(notary_fees, unit: "€", format: "%n %u")
  end

  def formatted_main_loan
    h.number_to_currency(main_loan_amount, unit: "€", format: "%n %u")
  end

  def formatted_ptz_amount
    h.number_to_currency(ptz_amount, unit: "€", format: "%n %u")
  end

  def formatted_real_effort
    h.number_to_currency(real_monthly_effort, unit: "€", format: "%n %u")
  end

  def formatted_debt_ratio
    "#{debt_ratio}%"
  end

  def debt_ratio_badge
    color = case debt_ratio&.to_f
            when 0..30 then "bg-green-100 text-green-800"
            when 30..35 then "bg-yellow-100 text-yellow-800"
            else "bg-red-100 text-red-800"
            end
    h.content_tag(:span, "#{debt_ratio}%", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{color}")
  end

  def danger_badge
    color = case danger_level
            when :critical then "bg-red-100 text-red-800"
            when :warning then "bg-yellow-100 text-yellow-800"
            else "bg-green-100 text-green-800"
            end
    h.content_tag(:span, danger_label, class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{color}")
  end

  def ptz_badge
    if ptz_eligible?
      h.content_tag(:span, "PTZ éligible", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800")
    else
      h.content_tag(:span, "PTZ non éligible", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600")
    end
  end

  def scenario_label
    { "standard" => "Standard", "optimiste" => "Optimiste", "pessimiste" => "Pessimiste" }[scenario]
  end
end
