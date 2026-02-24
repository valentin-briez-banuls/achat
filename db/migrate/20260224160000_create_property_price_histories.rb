class CreatePropertyPriceHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :property_price_histories do |t|
      t.references :property, null: false, foreign_key: true
      t.integer :price, null: false
      t.datetime :scraped_at, null: false
      t.string :source, null: false, default: "manual"

      t.timestamps
    end

    add_index :property_price_histories, [:property_id, :scraped_at]
  end
end
