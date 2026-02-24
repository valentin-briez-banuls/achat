class AddLoanChargesDistinctionToFinancialProfiles < ActiveRecord::Migration[8.1]
  def change
    # Nouveaux champs pour séparer crédits en cours vs charges courantes
    add_column :financial_profiles, :existing_loan_payments, :decimal, precision: 10, scale: 2, default: 0.0
    add_column :financial_profiles, :other_monthly_charges, :decimal, precision: 10, scale: 2, default: 0.0

    # Migration des données : on considère que monthly_charges = crédits en cours par défaut
    # L'utilisateur devra ajuster manuellement si besoin
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE financial_profiles 
          SET existing_loan_payments = monthly_charges,
              other_monthly_charges = 0
          WHERE monthly_charges IS NOT NULL AND monthly_charges > 0
        SQL
      end
    end
  end
end
