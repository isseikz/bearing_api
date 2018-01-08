class CreateRouteLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :route_logs do |t|
      t.integer :user_id
      t.float :latitude
      t.float :longitude
      t.float :speed
      t.float :bearing

      t.timestamps
    end
  end
end
