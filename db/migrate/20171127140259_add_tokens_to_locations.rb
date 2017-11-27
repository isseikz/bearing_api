class AddTokensToLocations < ActiveRecord::Migration[5.1]
  def change
    add_column :locations, :token, :string
  end
end
