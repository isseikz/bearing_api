class AddSpeedToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :speed, :float
  end
end
