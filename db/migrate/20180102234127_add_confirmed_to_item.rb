class AddConfirmedToItem < ActiveRecord::Migration

  def self.up
    add_column :items, :confirmed, :boolean, default: false
  end

  def self.down
    remove_column :items, :confirmed
  end

end
