# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140204191101) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "import_batches", force: true do |t|
    t.string   "batch_param"
    t.boolean  "is_active"
    t.json     "batch_errors"
    t.json     "extraction"
    t.integer  "import_job_id"
    t.boolean  "processed",     default: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "import_batches", ["batch_param", "import_job_id"], name: "index_import_batches_on_batch_param_and_import_job_id", unique: true, using: :btree
  add_index "import_batches", ["import_job_id"], name: "index_import_batches_on_import_job_id", using: :btree

  create_table "import_jobs", force: true do |t|
    t.boolean  "canceled",    default: false
    t.text     "notes"
    t.string   "name"
    t.json     "enrichments"
    t.json     "profile"
    t.datetime "last_run"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "records", force: true do |t|
    t.text     "title"
    t.json     "metadata"
    t.string   "record_hash"
    t.text     "identifier"
    t.string   "provider"
    t.boolean  "is_published"
    t.boolean  "is_live_revision"
    t.string   "lock_at_metadata_hash"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "transformation_batch_id"
  end

  add_index "records", ["identifier"], name: "index_records_on_identifier", using: :btree
  add_index "records", ["provider", "identifier"], name: "index_records_on_provider_and_identifier", unique: true, using: :btree
  add_index "records", ["provider"], name: "index_records_on_provider", using: :btree
  add_index "records", ["record_hash"], name: "index_records_on_record_hash", unique: true, using: :btree
  add_index "records", ["title"], name: "index_records_on_title", using: :btree
  add_index "records", ["transformation_batch_id"], name: "index_records_on_transformation_batch_id", using: :btree

  create_table "transformation_batches", force: true do |t|
    t.json     "batch_errors"
    t.json     "transformation"
    t.boolean  "is_active"
    t.integer  "step"
    t.integer  "import_batch_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "transformation_batches", ["import_batch_id"], name: "index_transformation_batches_on_import_batch_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.integer  "authorization_level"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "versions", force: true do |t|
    t.string   "item_type",               null: false
    t.integer  "item_id",                 null: false
    t.string   "event",                   null: false
    t.string   "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.boolean  "manual_edit"
    t.integer  "transformation_batch_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
