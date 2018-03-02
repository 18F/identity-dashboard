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

ActiveRecord::Schema.define(version: 20180302220332) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "agencies", force: :cascade do |t|
    t.string   "name",       null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "agencies", ["name"], name: "index_agencies_on_name", unique: true, using: :btree

  create_table "ar_internal_metadata", primary_key: "key", force: :cascade do |t|
    t.string   "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

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

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.string   "name",                     null: false
    t.text     "description", default: "", null: false
  end

  add_index "groups", ["name"], name: "index_groups_on_name", unique: true, using: :btree

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
    t.text     "sp_initiated_login_url"
    t.text     "return_to_sp_url"
    t.integer  "agency_id",                                             null: false
    t.json     "attribute_bundle"
    t.integer  "group_id"
    t.string   "logo"
    t.integer  "identity_protocol",                     default: 0
    t.json     "redirect_uris"
  end

  add_index "service_providers", ["group_id"], name: "index_service_providers_on_group_id", using: :btree
  add_index "service_providers", ["issuer"], name: "index_service_providers_on_issuer", unique: true, using: :btree

  create_table "user_groups", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "user_groups", ["group_id"], name: "index_user_groups_on_group_id", using: :btree
  add_index "user_groups", ["user_id"], name: "index_user_groups_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "uuid"
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
    t.integer  "group_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["group_id"], name: "index_users_on_group_id", using: :btree
  add_index "users", ["uuid"], name: "index_users_on_uuid", unique: true, using: :btree

  add_foreign_key "service_providers", "agencies"
  add_foreign_key "service_providers", "groups"
end
