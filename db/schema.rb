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

ActiveRecord::Schema[8.1].define(version: 2026_04_14_191048) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "transactions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "amount_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "idempotency_key"
    t.integer "kind", null: false
    t.uuid "recipient_id"
    t.datetime "updated_at", null: false
    t.uuid "user_id", null: false
    t.index ["idempotency_key"], name: "index_transactions_on_idempotency_key", unique: true
    t.index ["recipient_id"], name: "index_transactions_on_recipient_id"
    t.index ["user_id"], name: "index_transactions_on_user_id"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "balance_cents", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.check_constraint "balance_cents >= 0", name: "users_balance_cents_non_negative"
  end

  add_foreign_key "transactions", "users"
  add_foreign_key "transactions", "users", column: "recipient_id"
end
