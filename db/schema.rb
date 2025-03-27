# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_02_25_212140) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", precision: nil, null: false
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "agencies", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["name"], name: "index_agencies_on_name", unique: true
  end

  create_table "auth_tokens", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "encrypted_token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_auth_tokens_on_user_id"
  end

  create_table "banners", force: :cascade do |t|
    t.text "message"
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at", precision: nil
    t.datetime "locked_at", precision: nil
    t.datetime "failed_at", precision: nil
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "name", null: false
    t.text "description", default: ""
    t.integer "agency_id"
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.string "friendly_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name"
  end

  create_table "security_events", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "uuid"
    t.datetime "issued_at", precision: nil
    t.string "event_type"
    t.text "raw_event"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["issued_at"], name: "index_security_events_on_issued_at"
    t.index ["user_id"], name: "index_security_events_on_user_id"
    t.index ["uuid"], name: "index_security_events_on_uuid"
  end

  create_table "service_providers", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "issuer", null: false
    t.string "friendly_name", null: false
    t.text "description"
    t.text "metadata_url"
    t.text "acs_url"
    t.text "assertion_consumer_logout_service_url"
    t.integer "block_encryption", default: 1, null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.boolean "active", default: true, null: false
    t.boolean "approved", default: false, null: false
    t.text "sp_initiated_login_url"
    t.text "return_to_sp_url"
    t.integer "agency_id"
    t.json "attribute_bundle"
    t.integer "group_id"
    t.string "logo"
    t.integer "identity_protocol", default: 0
    t.json "redirect_uris"
    t.integer "ial"
    t.string "failure_to_proof_url"
    t.string "push_notification_url"
    t.jsonb "help_text", default: {"sign_in" => {}, "sign_up" => {}, "forgot_password" => {}}
    t.string "remote_logo_key"
    t.boolean "allow_prompt_login", default: false
    t.integer "default_aal"
    t.string "certs", array: true
    t.boolean "email_nameid_format_allowed", default: false
    t.boolean "signed_response_message_requested", default: false
    t.string "app_name", default: "", null: false
    t.boolean "prod_config", default: false, null: false
    t.string "post_idv_follow_up_url"
    t.index ["group_id"], name: "index_service_providers_on_group_id"
    t.index ["issuer"], name: "index_service_providers_on_issuer", unique: true
  end

  create_table "user_groups", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "group_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "role_name"
    t.index ["group_id"], name: "index_user_groups_on_group_id"
    t.index ["user_id"], name: "index_user_groups_on_user_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "uuid"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.boolean "admin", default: false, null: false
    t.integer "group_id"
    t.datetime "deleted_at", precision: nil
    t.index ["email"], name: "index_users_on_email", where: "(deleted_at IS NULL)"
    t.index ["group_id"], name: "index_users_on_group_id"
    t.index ["uuid"], name: "index_users_on_uuid", where: "(deleted_at IS NULL)"
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.datetime "created_at", precision: nil
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "wizard_steps", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "step_name", null: false
    t.json "wizard_form_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "step_name"], name: "index_wizard_steps_on_user_id_and_step_name", unique: true
    t.index ["user_id"], name: "index_wizard_steps_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "auth_tokens", "users"
  add_foreign_key "service_providers", "agencies"
  add_foreign_key "service_providers", "groups"
  add_foreign_key "wizard_steps", "users"
end
