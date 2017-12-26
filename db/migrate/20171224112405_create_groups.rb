class CreateGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :groups do |t|
      t.float :reference_latitude
      t.float :reference_longitude

      t.timestamps
    end
  end
end
