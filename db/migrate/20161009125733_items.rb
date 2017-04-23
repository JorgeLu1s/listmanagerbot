class Items < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :name
      t.string :list
      t.string :chat
      t.string :user

      t.timestamps
    end
  end
end
