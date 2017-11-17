class AddBearingsToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :bearing, :float
  end
end
