class CreateImportBatches < ActiveRecord::Migration
  def change
    create_table :import_batches do |t|
      t.string :batch_param
      t.boolean :is_active
      t.json :batch_errors
      t.json :extraction
      t.references :import_job, index: true
      # Flag used to allow us to process batches concurrently and recursively
      # without re-processing the same batch twice.
      t.boolean :processed, default: false
      t.timestamps
    end
    add_index :import_batches, [:batch_param, :import_job_id], unique:  true
  end
end