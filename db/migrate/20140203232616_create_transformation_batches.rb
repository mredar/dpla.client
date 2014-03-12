class CreateTransformationBatches < ActiveRecord::Migration
  def change
    create_table :transformation_batches do |t|
      t.json :batch_errors
      t.json :transformation
      t.boolean :is_active
      t.integer :step
      t.references :import_batch, index: true
      t.timestamps
    end
  end
end