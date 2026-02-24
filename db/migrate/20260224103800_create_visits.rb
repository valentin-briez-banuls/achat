class CreateVisits < ActiveRecord::Migration[8.1]
  def change
    create_table :visits do |t|
      t.references :property, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0  # planifiée, effectuée, annulée
      t.integer :verdict  # 0=négatif, 1=neutre, 2=positif, 3=coup_de_coeur
      t.text :notes
      t.text :pros
      t.text :cons

      t.timestamps
    end

    add_index :visits, :scheduled_at
  end
end
