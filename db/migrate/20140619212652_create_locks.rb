class CreateLocks < ActiveRecord::Migration
  def change
    create_table :locks do |t|
      t.references :environment, index: true
      t.references :app, index: true
      t.references :user, index: true
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
