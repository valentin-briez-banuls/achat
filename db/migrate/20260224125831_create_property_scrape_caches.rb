class CreatePropertyScrapeCaches < ActiveRecord::Migration[8.1]
  def change
    create_table :property_scrape_caches do |t|
      t.string :url_hash
      t.jsonb :scraped_data
      t.jsonb :images_urls
      t.datetime :expires_at

      t.timestamps
    end
    add_index :property_scrape_caches, :url_hash
    add_index :property_scrape_caches, :expires_at
  end
end
