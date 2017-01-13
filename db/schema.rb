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

ActiveRecord::Schema.define(version: 20170113162235) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "service_providers", force: :cascade do |t|
    t.integer  "user_id",                                               null: false
    t.string   "issuer",                                                null: false
    t.string   "friendly_name"
    t.text     "description"
    t.text     "metadata_url"
    t.text     "acs_url"
    t.text     "assertion_consumer_logout_service_url"
    t.text     "saml_client_cert"
    t.integer  "block_encryption",                      default: 1,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                                default: false, null: false
    t.boolean  "approved",                              default: false, null: false
    t.string   "agency"
    t.text     "sp_initiated_login_url"
    t.text     "return_to_sp_url"
  end

  add_index "service_providers", ["issuer"], name: "index_service_providers_on_issuer", unique: true, using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uuid",                               null: false
    t.string   "email",                              null: false
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "sign_in_count",      default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.boolean  "admin",              default: false, null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", unique: true, using: :btree

end
