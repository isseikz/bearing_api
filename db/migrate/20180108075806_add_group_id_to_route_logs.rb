class AddGroupIdToRouteLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :route_logs, :group_id, :integer
  end
end
