class CreateUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :users do |t|
      t.string :token
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.float :bearing

      t.timestamps
    end
  end
end
