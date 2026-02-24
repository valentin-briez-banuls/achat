class CreateSimulations < ActiveRecord::Migration[8.1]
  def change
    create_table :simulations do |t|
      t.references :property, null: false, foreign_key: true

      t.string :name
      t.integer :scenario, default: 0  # standard, optimiste, pessimiste

      # Paramètres d'entrée
      t.decimal :loan_rate, precision: 5, scale: 3
      t.integer :loan_duration_years
      t.decimal :personal_contribution, precision: 12, scale: 2
      t.decimal :negotiated_price, precision: 12, scale: 2
      t.decimal :additional_works, precision: 10, scale: 2, default: 0
      t.decimal :price_negotiation_percent, precision: 5, scale: 2, default: 0

      # Résultats calculés
      t.decimal :notary_fees, precision: 10, scale: 2
      t.decimal :total_project_cost, precision: 12, scale: 2
      t.decimal :ptz_amount, precision: 12, scale: 2, default: 0
      t.decimal :main_loan_amount, precision: 12, scale: 2
      t.decimal :monthly_payment_main, precision: 10, scale: 2
      t.decimal :monthly_payment_ptz, precision: 10, scale: 2, default: 0
      t.decimal :total_monthly_payment, precision: 10, scale: 2
      t.decimal :total_credit_cost, precision: 12, scale: 2
      t.decimal :real_monthly_effort, precision: 10, scale: 2
      t.decimal :debt_ratio, precision: 5, scale: 2
      t.boolean :ptz_eligible, default: false

      t.timestamps
    end

    add_index :simulations, :property_id
  end
end
