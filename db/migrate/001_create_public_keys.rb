class CreatePublicKeys < ActiveRecord::Migration
  def change
    create_table :public_keys do |t|
      t.references :user
      t.text :content
      t.string :comment

      # Neccessary to provide uniqueness of content (an index on field with type text is difficult)
      t.string :checksum

      t.timestamps
    end
    add_index :public_keys, :user_id
    add_index :public_keys, :checksum, :unique => true
  end
end
