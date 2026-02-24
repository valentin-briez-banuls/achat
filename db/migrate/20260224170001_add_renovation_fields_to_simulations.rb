class AddRenovationFieldsToSimulations < ActiveRecord::Migration[8.1]
  def change
    add_column :simulations, :renovation_budget_included, :boolean, default: false, null: false
    add_column :simulations, :renovation_budget, :integer, default: 0
  end
end
