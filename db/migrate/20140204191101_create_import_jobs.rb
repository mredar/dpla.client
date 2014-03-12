class CreateImportJobs < ActiveRecord::Migration
  def change
    create_table :import_jobs do |t|
      t.boolean :canceled, :default => false
      t.text :notes
      t.string :name
      t.json :enrichments
      t.json :profile
      t.datetime :last_run
      t.timestamps
    end
  end
end