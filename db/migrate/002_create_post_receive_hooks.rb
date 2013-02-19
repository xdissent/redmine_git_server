class CreatePostReceiveHooks < ActiveRecord::Migration
  def change
    create_table :post_receive_hooks do |t|
      t.string :name
      t.references :repository
      t.string :url

      t.timestamps
    end
    add_index :post_receive_hooks, :repository_id
  end
end
