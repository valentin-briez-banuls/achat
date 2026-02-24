class CreatePropertyCriteria < ActiveRecord::Migration[8.1]
  def change
    create_table :property_criteria do |t|
      t.references :household, null: false, foreign_key: true, index: { unique: true }

      # Critères obligatoires
      t.decimal :max_budget, precision: 12, scale: 2
      t.decimal :min_surface, precision: 8, scale: 2
      t.integer :min_bedrooms, default: 1
      t.boolean :outdoor_required, default: false
      t.boolean :parking_required, default: false
      t.decimal :max_work_distance_km, precision: 6, scale: 1
      t.string :geographic_zone
      t.integer :property_condition, default: 0  # ancien / neuf
      t.string :min_energy_class  # A, B, C, D, E, F, G

      # Critères pondérés (poids 0-10)
      t.integer :weight_neighborhood, default: 5
      t.integer :weight_view, default: 5
      t.integer :weight_orientation, default: 5
      t.integer :weight_renovation, default: 5
      t.integer :weight_quietness, default: 5
      t.integer :weight_brightness, default: 5

      t.timestamps
    end

  end
end
