class CreatePropertyScores < ActiveRecord::Migration[8.1]
  def change
    create_table :property_scores do |t|
      t.references :property, null: false, foreign_key: true

      t.integer :total_score, default: 0  # /100
      t.integer :compatibility  # 0=non_compatible, 1=partielle, 2=stricte

      # Détail des scores
      t.integer :budget_score, default: 0
      t.integer :surface_score, default: 0
      t.integer :bedrooms_score, default: 0
      t.integer :outdoor_score, default: 0
      t.integer :parking_score, default: 0
      t.integer :energy_score, default: 0
      t.integer :location_score, default: 0
      t.integer :neighborhood_score, default: 0
      t.integer :view_score, default: 0
      t.integer :orientation_score, default: 0
      t.integer :renovation_score, default: 0
      t.integer :quietness_score, default: 0
      t.integer :brightness_score, default: 0

      t.jsonb :details, default: {}

      t.timestamps
    end

    add_index :property_scores, :property_id, unique: true
    add_index :property_scores, :total_score
  end
end
