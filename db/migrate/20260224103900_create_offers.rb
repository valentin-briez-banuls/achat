class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.references :property, null: false, foreign_key: true

      t.decimal :amount, precision: 12, scale: 2, null: false
      t.date :offered_on, null: false
      t.date :response_deadline
      t.integer :status, default: 0  # en_attente, acceptée, refusée, contre_offre, expirée
      t.text :conditions
      t.text :notes
      t.decimal :counter_offer_amount, precision: 12, scale: 2

      t.timestamps
    end

    add_index :offers, :property_id
    add_index :offers, :status
  end
end
