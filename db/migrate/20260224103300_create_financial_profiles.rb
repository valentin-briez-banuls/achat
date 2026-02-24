class CreateFinancialProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_profiles do |t|
      t.references :household, null: false, foreign_key: true, index: { unique: true }

      # Revenus
      t.decimal :salary_person_1, precision: 10, scale: 2, default: 0
      t.decimal :salary_person_2, precision: 10, scale: 2, default: 0
      t.decimal :other_income, precision: 10, scale: 2, default: 0

      # Charges
      t.decimal :monthly_charges, precision: 10, scale: 2, default: 0

      # Apport & Épargne
      t.decimal :personal_contribution, precision: 12, scale: 2, default: 0
      t.decimal :remaining_savings, precision: 12, scale: 2, default: 0

      # Contrats
      t.integer :contract_type_person_1, default: 0
      t.integer :contract_type_person_2, default: 0

      # Prêt
      t.decimal :proposed_rate, precision: 5, scale: 3
      t.integer :desired_duration_years, default: 25

      # Situation fiscale
      t.decimal :fiscal_reference_income, precision: 12, scale: 2, default: 0
      t.integer :household_size, default: 2
      t.string :ptz_zone

      # Calculs (cached)
      t.decimal :borrowing_capacity, precision: 12, scale: 2
      t.decimal :debt_ratio, precision: 5, scale: 2
      t.decimal :max_monthly_payment, precision: 10, scale: 2
      t.decimal :remaining_to_live, precision: 10, scale: 2

      t.timestamps
    end

  end
end
