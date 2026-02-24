class CreateHouseholds < ActiveRecord::Migration[8.1]
  def change
    create_table :households do |t|
      t.string :name, null: false
      t.string :invitation_token
      t.timestamps
    end

    add_index :households, :invitation_token, unique: true
  end
end
