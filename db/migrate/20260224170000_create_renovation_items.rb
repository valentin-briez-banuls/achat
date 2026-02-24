class CreateRenovationItems < ActiveRecord::Migration[8.1]
  def change
    create_table :renovation_items do |t|
      t.references :property, null: false, foreign_key: true

      t.integer :category, null: false  # enum
      t.string :description
      t.integer :estimated_cost_min, null: false, default: 0
      t.integer :estimated_cost_max, null: false, default: 0

      t.timestamps
    end
  end
end
