class FinancialProfileDecorator < Draper::Decorator
  delegate_all

  def formatted_salary_1
    h.number_to_currency(salary_person_1, unit: "€", format: "%n %u")
  end

  def formatted_salary_2
    h.number_to_currency(salary_person_2, unit: "€", format: "%n %u")
  end

  def formatted_total_income
    h.number_to_currency(total_monthly_income, unit: "€", format: "%n %u")
  end

  def formatted_borrowing_capacity
    h.number_to_currency(borrowing_capacity, unit: "€", format: "%n %u")
  end

  def formatted_max_monthly_payment
    h.number_to_currency(max_monthly_payment, unit: "€", format: "%n %u")
  end

  def formatted_remaining_to_live
    h.number_to_currency(remaining_to_live, unit: "€", format: "%n %u")
  end

  def formatted_debt_ratio
    "#{debt_ratio}%"
  end

  def debt_ratio_color
    case debt_ratio&.to_f
    when 0..25 then "text-green-600"
    when 25..33 then "text-yellow-600"
    else "text-red-600"
    end
  end

  def contract_label_1
    contract_labels[contract_type_person_1]
  end

  def contract_label_2
    contract_labels[contract_type_person_2]
  end

  private

  def contract_labels
    {
      "cdi_1" => "CDI", "cdd_1" => "CDD", "freelance_1" => "Freelance", "fonctionnaire_1" => "Fonctionnaire",
      "cdi_2" => "CDI", "cdd_2" => "CDD", "freelance_2" => "Freelance", "fonctionnaire_2" => "Fonctionnaire",
      "none_2" => "—"
    }
  end
end
