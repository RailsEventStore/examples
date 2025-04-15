class CreateTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :tenants do |t|
      t.string :name, null: false
      t.string :host, null: false

      t.timestamps
    end
  end
end
