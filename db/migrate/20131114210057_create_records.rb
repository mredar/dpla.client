class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.text :title
      t.json :metadata
      # provider + identifier + metadata.to_json = record_hash
      # Rather than set a brittle multifield index for metadata json fields,
      # I have created a hash of the identifier provider and metadata.to_json
      # data for the purpose of record lookup and preventing duplicates
      t.string :record_hash
      t.text :identifier
      t.string :provider
      # is_publised: show this record in public-facing apis?
      t.boolean :is_published
      # Revisions are: two records with the same identifier and prvider field data
      # but with different metadata_hashes. One revision must be the "live"
      # revision. This allows us to change revisions by simply setting a flag,
      t.boolean :is_live_revision
      # In the case of manual edits, we do not want a record added via an
      # automated batch import to declare itself as live. So, if
      # lock_as_live_revision == true, we always set is_live_revision = false
      t.boolean :lock_as_live_revision
      t.timestamps
      t.references :transformation_batch, index: true
    end
    add_index :records, :record_hash, unique: true
    add_index :records, :title
    add_index :records, :identifier
    add_index :records, :provider
  end
end
