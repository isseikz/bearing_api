class CreateUserAroundMes < ActiveRecord::Migration[5.1]
  def change
    create_table :user_around_mes do |t|
      t.integer :user1_id
      t.integer :user2_id

      t.timestamps
    end
  end
end
