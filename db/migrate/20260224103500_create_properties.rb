class CreateProperties < ActiveRecord::Migration[8.1]
  def change
    create_table :properties do |t|
      t.references :household, null: false, foreign_key: true

      # Infos principales
      t.string :title, null: false
      t.decimal :price, precision: 12, scale: 2, null: false
      t.decimal :surface, precision: 8, scale: 2, null: false
      t.integer :property_type, default: 0  # appartement, maison, terrain, etc.
      t.integer :rooms
      t.integer :bedrooms

      # Localisation
      t.string :city, null: false
      t.string :postal_code, null: false
      t.string :address
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7

      # Financier
      t.decimal :agency_fees, precision: 10, scale: 2, default: 0
      t.boolean :agency_fees_included, default: true
      t.decimal :notary_fees_estimate, precision: 10, scale: 2
      t.decimal :copro_charges_monthly, precision: 8, scale: 2, default: 0
      t.decimal :property_tax_yearly, precision: 8, scale: 2, default: 0
      t.decimal :estimated_works, precision: 10, scale: 2, default: 0

      # Caractéristiques
      t.string :energy_class  # DPE: A-G
      t.string :ges_class  # GES: A-G
      t.integer :condition, default: 0  # ancien / neuf
      t.boolean :has_outdoor, default: false
      t.boolean :has_parking, default: false
      t.integer :floor
      t.integer :total_floors

      # Scoring subjectif (rempli par l'utilisateur)
      t.integer :score_neighborhood  # 1-5
      t.integer :score_view  # 1-5
      t.integer :score_orientation  # 1-5
      t.integer :score_renovation  # 1-5
      t.integer :score_quietness  # 1-5
      t.integer :score_brightness  # 1-5

      # Statut & méta
      t.integer :status, default: 0
      t.string :listing_url
      t.text :personal_notes

      t.timestamps
    end

    add_index :properties, :household_id
    add_index :properties, :status
    add_index :properties, :city
    add_index :properties, :postal_code
  end
end
