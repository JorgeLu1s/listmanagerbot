class ChangeNameAndListType < ActiveRecord::Migration

  def change
    enable_extension :citext
    change_column :items, :name, :citext
    change_column :items, :list, :citext
  end

end
