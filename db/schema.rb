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

ActiveRecord::Schema.define(version: 20151202183554) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "hstore"
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "postgis"
  enable_extension "tablefunc"
  enable_extension "btree_gist"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "resource_id",   limit: 255, null: false
    t.string   "resource_type", limit: 255, null: false
    t.integer  "author_id"
    t.string   "author_type",   limit: 255
    t.text     "body"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "namespace",     limit: 255
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_admin_notes_on_resource_type_and_resource_id", using: :btree

  create_table "activities", force: :cascade do |t|
    t.integer  "activity_type_id"
    t.integer  "activitable_id"
    t.string   "activitable_type", limit: 255
    t.integer  "campaign_id"
    t.boolean  "active",                       default: true
    t.integer  "company_user_id"
    t.datetime "activity_date"
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  add_index "activities", ["activitable_id", "activitable_type"], name: "index_activities_on_activitable_id_and_activitable_type", using: :btree
  add_index "activities", ["activity_type_id"], name: "index_activities_on_activity_type_id", using: :btree
  add_index "activities", ["company_user_id"], name: "index_activities_on_company_user_id", using: :btree

  create_table "activity_type_campaigns", force: :cascade do |t|
    t.integer  "activity_type_id"
    t.integer  "campaign_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
  end

  add_index "activity_type_campaigns", ["activity_type_id"], name: "index_activity_type_campaigns_on_activity_type_id", using: :btree
  add_index "activity_type_campaigns", ["campaign_id"], name: "index_activity_type_campaigns_on_campaign_id", using: :btree

  create_table "activity_types", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.text     "description"
    t.boolean  "active",                    default: true
    t.integer  "company_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  add_index "activity_types", ["company_id"], name: "index_activity_types_on_company_id", using: :btree

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                      default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "alerts_users", force: :cascade do |t|
    t.integer  "company_user_id"
    t.string   "name",            limit: 255
    t.integer  "version"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "alerts_users", ["company_user_id"], name: "index_alerts_users_on_company_user_id", using: :btree

  create_table "areas", force: :cascade do |t|
    t.string   "name",                          limit: 255
    t.text     "description"
    t.boolean  "active",                                    default: true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                               null: false
    t.datetime "updated_at",                                               null: false
    t.text     "common_denominators"
    t.integer  "common_denominators_locations",             default: [],                array: true
  end

  add_index "areas", ["common_denominators_locations"], name: "index_areas_on_common_denominators_locations", using: :gin
  add_index "areas", ["company_id"], name: "index_areas_on_company_id", using: :btree

  create_table "areas_campaigns", force: :cascade do |t|
    t.integer "area_id"
    t.integer "campaign_id"
    t.integer "exclusions",  default: [], array: true
    t.integer "inclusions",  default: [], array: true
  end

  create_table "asset_downloads", force: :cascade do |t|
    t.string   "uid",               limit: 255
    t.text     "assets_ids"
    t.string   "aasm_state",        limit: 255
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "user_id"
    t.datetime "last_downloaded"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  add_index "asset_downloads", ["user_id"], name: "index_asset_downloads_on_user_id", using: :btree

  create_table "attached_assets", force: :cascade do |t|
    t.string   "file_file_name",        limit: 255
    t.string   "file_content_type",     limit: 255
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "asset_type",            limit: 255
    t.integer  "attachable_id"
    t.string   "attachable_type",       limit: 255
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.boolean  "active",                            default: true
    t.string   "direct_upload_url",     limit: 255
    t.integer  "rating",                            default: 0
    t.integer  "folder_id"
    t.integer  "status",                            default: 0
    t.integer  "processing_percentage",             default: 0
  end

  add_index "attached_assets", ["attachable_type", "attachable_id"], name: "index_attached_assets_on_attachable_type_and_attachable_id", using: :btree
  add_index "attached_assets", ["direct_upload_url"], name: "index_attached_assets_on_direct_upload_url", unique: true, using: :btree
  add_index "attached_assets", ["folder_id"], name: "index_attached_assets_on_folder_id", using: :btree

  create_table "attached_assets_tags", force: :cascade do |t|
    t.integer "attached_asset_id"
    t.integer "tag_id"
  end

  add_index "attached_assets_tags", ["attached_asset_id"], name: "index_attached_assets_tags_on_attached_asset_id", using: :btree
  add_index "attached_assets_tags", ["tag_id"], name: "index_attached_assets_tags_on_tag_id", using: :btree

  create_table "brand_ambassadors_visits", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "company_user_id"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "active",                      default: true
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "description"
    t.string   "visit_type",      limit: 255
    t.integer  "area_id"
    t.string   "city",            limit: 255
    t.integer  "campaign_id"
  end

  add_index "brand_ambassadors_visits", ["area_id"], name: "index_brand_ambassadors_visits_on_area_id", using: :btree
  add_index "brand_ambassadors_visits", ["campaign_id"], name: "index_brand_ambassadors_visits_on_campaign_id", using: :btree
  add_index "brand_ambassadors_visits", ["company_id"], name: "index_brand_ambassadors_visits_on_company_id", using: :btree
  add_index "brand_ambassadors_visits", ["company_user_id"], name: "index_brand_ambassadors_visits_on_company_user_id", using: :btree

  create_table "brand_portfolios", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.boolean  "active",                    default: true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.text     "description"
  end

  add_index "brand_portfolios", ["company_id"], name: "index_brand_portfolios_on_company_id", using: :btree

  create_table "brand_portfolios_brands", force: :cascade do |t|
    t.integer "brand_id"
    t.integer "brand_portfolio_id"
  end

  add_index "brand_portfolios_brands", ["brand_id", "brand_portfolio_id"], name: "brand_portfolio_unique_idx", unique: true, using: :btree
  add_index "brand_portfolios_brands", ["brand_id"], name: "index_brand_portfolios_brands_on_brand_id", using: :btree
  add_index "brand_portfolios_brands", ["brand_portfolio_id"], name: "index_brand_portfolios_brands_on_brand_portfolio_id", using: :btree

  create_table "brand_portfolios_campaigns", force: :cascade do |t|
    t.integer "brand_portfolio_id"
    t.integer "campaign_id"
  end

  add_index "brand_portfolios_campaigns", ["brand_portfolio_id"], name: "index_brand_portfolios_campaigns_on_brand_portfolio_id", using: :btree
  add_index "brand_portfolios_campaigns", ["campaign_id"], name: "index_brand_portfolios_campaigns_on_campaign_id", using: :btree

  create_table "brands", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.integer  "company_id"
    t.boolean  "active",                    default: true
  end

  add_index "brands", ["company_id"], name: "index_brands_on_company_id", using: :btree

  create_table "brands_campaigns", force: :cascade do |t|
    t.integer "brand_id"
    t.integer "campaign_id"
  end

  add_index "brands_campaigns", ["brand_id"], name: "index_brands_campaigns_on_brand_id", using: :btree
  add_index "brands_campaigns", ["campaign_id"], name: "index_brands_campaigns_on_campaign_id", using: :btree

  create_table "campaigns", force: :cascade do |t|
    t.string   "name",             limit: 255
    t.text     "description"
    t.string   "aasm_state",       limit: 255
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "company_id"
    t.integer  "first_event_id"
    t.integer  "last_event_id"
    t.datetime "first_event_at"
    t.datetime "last_event_at"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "survey_brand_ids",             default: [],              array: true
    t.text     "modules"
    t.string   "color",            limit: 30
  end

  add_index "campaigns", ["company_id"], name: "index_campaigns_on_company_id", using: :btree

  create_table "campaigns_date_ranges", force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "date_range_id"
  end

  create_table "campaigns_day_parts", force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "day_part_id"
  end

  create_table "campaigns_teams", force: :cascade do |t|
    t.integer "campaign_id"
    t.integer "team_id"
  end

  add_index "campaigns_teams", ["campaign_id"], name: "index_campaigns_teams_on_campaign_id", using: :btree
  add_index "campaigns_teams", ["team_id"], name: "index_campaigns_teams_on_team_id", using: :btree

  create_table "comments", force: :cascade do |t|
    t.integer  "commentable_id"
    t.string   "commentable_type", limit: 255
    t.text     "content"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "comments", ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id", using: :btree
  add_index "comments", ["created_at"], name: "index_comments_on_created_at", using: :btree

  create_table "companies", force: :cascade do |t|
    t.string   "name",               limit: 255
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
    t.boolean  "timezone_support"
    t.hstore   "settings"
    t.text     "expense_categories"
  end

  create_table "company_users", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.boolean  "active",                              default: true
    t.datetime "last_activity_at"
    t.string   "notifications_settings",  limit: 255, default: [],                array: true
    t.datetime "last_activity_mobile_at"
    t.string   "tableau_username",        limit: 255
  end

  add_index "company_users", ["company_id"], name: "index_company_users_on_company_id", using: :btree
  add_index "company_users", ["user_id"], name: "index_company_users_on_user_id", using: :btree

  create_table "contact_events", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "contactable_id"
    t.string   "contactable_type", limit: 255
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "contact_events", ["contactable_id", "contactable_type"], name: "index_contact_events_on_contactable_id_and_contactable_type", using: :btree
  add_index "contact_events", ["event_id"], name: "index_contact_events_on_event_id", using: :btree

  create_table "contacts", force: :cascade do |t|
    t.integer  "company_id"
    t.string   "first_name",    limit: 255
    t.string   "last_name",     limit: 255
    t.string   "title",         limit: 255
    t.string   "email",         limit: 255
    t.string   "phone_number",  limit: 255
    t.string   "street1",       limit: 255
    t.string   "street2",       limit: 255
    t.string   "country",       limit: 255
    t.string   "state",         limit: 255
    t.string   "city",          limit: 255
    t.string   "zip_code",      limit: 255
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "company_name",  limit: 255
  end

  create_table "custom_filters", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "apply_to",     limit: 255
    t.text     "filters"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "owner_id"
    t.string   "owner_type",   limit: 255
    t.boolean  "default_view",             default: false
    t.integer  "category_id"
  end

  create_table "custom_filters_categories", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "custom_filters_categories", ["company_id"], name: "index_custom_filters_categories_on_company_id", using: :btree

  create_table "data_extracts", force: :cascade do |t|
    t.string   "type",             limit: 255
    t.integer  "company_id"
    t.boolean  "active",                       default: true
    t.string   "sharing",          limit: 255
    t.string   "name",             limit: 255
    t.text     "description"
    t.text     "columns"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "default_sort_by",  limit: 255
    t.string   "default_sort_dir", limit: 255
    t.text     "params"
  end

  add_index "data_extracts", ["company_id"], name: "index_data_extracts_on_company_id", using: :btree
  add_index "data_extracts", ["created_by_id"], name: "index_data_extracts_on_created_by_id", using: :btree
  add_index "data_extracts", ["updated_by_id"], name: "index_data_extracts_on_updated_by_id", using: :btree

  create_table "data_migrations", force: :cascade do |t|
    t.integer  "remote_id"
    t.string   "remote_type", limit: 255
    t.integer  "local_id"
    t.string   "local_type",  limit: 255
    t.integer  "company_id"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
  end

  create_table "date_items", force: :cascade do |t|
    t.integer  "date_range_id"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "recurrence",                    default: false
    t.string   "recurrence_type",   limit: 255
    t.integer  "recurrence_period"
    t.string   "recurrence_days",   limit: 255
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  create_table "date_ranges", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.text     "description"
    t.boolean  "active",                    default: true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "day_items", force: :cascade do |t|
    t.integer  "day_part_id"
    t.time     "start_time"
    t.time     "end_time"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "day_parts", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.text     "description"
    t.boolean  "active",                    default: true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",               default: 0, null: false
    t.integer  "attempts",               default: 0, null: false
    t.text     "handler",                            null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by",  limit: 255
    t.string   "queue",      limit: 255
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
  end

  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree

  create_table "document_folders", force: :cascade do |t|
    t.string   "name",            limit: 255
    t.integer  "parent_id"
    t.boolean  "active",                      default: true
    t.integer  "documents_count"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "folderable_id"
    t.string   "folderable_type", limit: 255
  end

  add_index "document_folders", ["company_id"], name: "index_document_folders_on_company_id", using: :btree
  add_index "document_folders", ["parent_id"], name: "index_document_folders_on_parent_id", using: :btree

  create_table "entity_forms", force: :cascade do |t|
    t.string   "entity",     limit: 255
    t.integer  "entity_id"
    t.integer  "company_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "entity_forms", ["entity", "company_id"], name: "index_entity_forms_on_entity_and_company_id", unique: true, using: :btree

  create_table "event_data", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "impressions",                                        default: 0
    t.integer  "interactions",                                       default: 0
    t.integer  "samples",                                            default: 0
    t.decimal  "gender_female",             precision: 5,  scale: 2, default: 0.0
    t.decimal  "gender_male",               precision: 5,  scale: 2, default: 0.0
    t.decimal  "ethnicity_asian",           precision: 5,  scale: 2, default: 0.0
    t.decimal  "ethnicity_black",           precision: 5,  scale: 2, default: 0.0
    t.decimal  "ethnicity_hispanic",        precision: 5,  scale: 2, default: 0.0
    t.decimal  "ethnicity_native_american", precision: 5,  scale: 2, default: 0.0
    t.decimal  "ethnicity_white",           precision: 5,  scale: 2, default: 0.0
    t.decimal  "spent",                     precision: 10, scale: 2, default: 0.0
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
  end

  add_index "event_data", ["event_id"], name: "index_event_data_on_event_id", using: :btree

  create_table "event_expenses", force: :cascade do |t|
    t.integer  "event_id"
    t.decimal  "amount",                    precision: 15, scale: 2, default: 0.0
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.integer  "brand_id"
    t.string   "category",      limit: 255
    t.date     "expense_date"
    t.boolean  "reimbursable"
    t.boolean  "billable"
    t.string   "merchant",      limit: 255
    t.text     "description"
  end

  add_index "event_expenses", ["brand_id"], name: "index_event_expenses_on_brand_id", using: :btree
  add_index "event_expenses", ["event_id"], name: "index_event_expenses_on_event_id", using: :btree

  create_table "events", force: :cascade do |t|
    t.integer  "campaign_id"
    t.integer  "company_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "aasm_state",          limit: 255
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                                             null: false
    t.datetime "updated_at",                                                             null: false
    t.boolean  "active",                                                  default: true
    t.integer  "place_id"
    t.decimal  "promo_hours",                     precision: 6, scale: 2, default: 0.0
    t.text     "reject_reason"
    t.string   "timezone",            limit: 255
    t.datetime "local_start_at"
    t.datetime "local_end_at"
    t.text     "description"
    t.string   "kbmg_event_id",       limit: 255
    t.datetime "rejected_at"
    t.datetime "submitted_at"
    t.datetime "approved_at"
    t.integer  "active_photos_count",                                     default: 0
    t.integer  "visit_id"
    t.integer  "results_version",                                         default: 0
  end

  add_index "events", ["aasm_state"], name: "index_events_on_aasm_state", using: :btree
  add_index "events", ["campaign_id"], name: "index_events_on_campaign_id", using: :btree
  add_index "events", ["company_id"], name: "index_events_on_company_id", using: :btree
  add_index "events", ["place_id"], name: "index_events_on_place_id", using: :btree
  add_index "events", ["visit_id"], name: "index_events_on_visit_id", using: :btree

  create_table "filter_settings", force: :cascade do |t|
    t.integer  "company_user_id"
    t.string   "apply_to",        limit: 255
    t.text     "settings"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "filter_settings", ["company_user_id"], name: "index_filter_settings_on_company_user_id", using: :btree

  create_table "form_field_options", force: :cascade do |t|
    t.integer  "form_field_id"
    t.string   "name",          limit: 255
    t.integer  "ordering"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.string   "option_type",   limit: 255
  end

  add_index "form_field_options", ["form_field_id", "option_type"], name: "index_form_field_options_on_form_field_id_and_option_type", using: :btree
  add_index "form_field_options", ["form_field_id"], name: "index_form_field_options_on_form_field_id", using: :btree

  create_table "form_field_results", force: :cascade do |t|
    t.integer  "form_field_id"
    t.text     "value"
    t.datetime "created_at",                                                         null: false
    t.datetime "updated_at",                                                         null: false
    t.hstore   "hash_value"
    t.decimal  "scalar_value",                precision: 15, scale: 2, default: 0.0
    t.integer  "resultable_id"
    t.string   "resultable_type", limit: 255
  end

  add_index "form_field_results", ["form_field_id", "resultable_id", "resultable_type"], name: "idx_ff_res_on_form_field_id_n_resultable_id_n_resultable_type", unique: true, using: :btree
  add_index "form_field_results", ["form_field_id"], name: "index_activity_results_on_form_field_id", using: :btree
  add_index "form_field_results", ["hash_value"], name: "index_activity_results_on_hash_value", using: :gist
  add_index "form_field_results", ["resultable_id", "resultable_type", "form_field_id"], name: "index_ff_results_on_resultable_and_form_field_id", using: :btree
  add_index "form_field_results", ["resultable_id", "resultable_type"], name: "index_form_field_results_on_resultable_id_and_resultable_type", using: :btree

  create_table "form_fields", force: :cascade do |t|
    t.integer  "fieldable_id"
    t.string   "fieldable_type", limit: 255
    t.string   "name",           limit: 255
    t.string   "type",           limit: 255
    t.text     "settings"
    t.integer  "ordering"
    t.boolean  "required"
    t.datetime "created_at",                 null: false
    t.datetime "updated_at",                 null: false
    t.integer  "kpi_id"
    t.boolean  "multiple"
  end

  add_index "form_fields", ["fieldable_id", "fieldable_type"], name: "index_form_fields_on_fieldable_id_and_fieldable_type", using: :btree

  create_table "goals", force: :cascade do |t|
    t.integer  "kpi_id"
    t.integer  "kpis_segment_id"
    t.decimal  "value"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.integer  "goalable_id"
    t.string   "goalable_type",    limit: 255
    t.integer  "parent_id"
    t.string   "parent_type",      limit: 255
    t.string   "title",            limit: 255
    t.date     "start_date"
    t.date     "due_date"
    t.integer  "activity_type_id"
  end

  add_index "goals", ["goalable_id", "goalable_type"], name: "index_goals_on_goalable_id_and_goalable_type", using: :btree
  add_index "goals", ["kpi_id"], name: "index_goals_on_kpi_id", using: :btree
  add_index "goals", ["kpis_segment_id"], name: "index_goals_on_kpis_segment_id", using: :btree

  create_table "hours_fields", force: :cascade do |t|
    t.integer  "venue_id"
    t.integer  "day"
    t.string   "hour_open",  limit: 255
    t.string   "hour_close", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "hours_fields", ["venue_id"], name: "index_hours_fields_on_venue_id", using: :btree

  create_table "invite_rsvps", force: :cascade do |t|
    t.integer  "invite_id"
    t.integer  "registrant_id"
    t.date     "date_added"
    t.string   "email",                            limit: 255
    t.string   "mobile_phone",                     limit: 255
    t.boolean  "mobile_signup"
    t.string   "first_name",                       limit: 255
    t.string   "last_name",                        limit: 255
    t.string   "attended_previous_bartender_ball", limit: 255
    t.boolean  "opt_in_to_future_communication"
    t.integer  "primary_registrant_id"
    t.string   "bartender_how_long",               limit: 255
    t.string   "bartender_role",                   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "date_of_birth",                    limit: 255
    t.string   "zip_code",                         limit: 255
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "attended"
  end

  add_index "invite_rsvps", ["invite_id"], name: "index_invite_rsvps_on_invite_id", using: :btree

  create_table "invites", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "venue_id"
    t.string   "market",        limit: 255
    t.integer  "invitees",                  default: 0
    t.integer  "rsvps_count",               default: 0
    t.integer  "attendees",                 default: 0
    t.date     "final_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "active",                    default: true
    t.integer  "area_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  add_index "invites", ["area_id"], name: "index_invites_on_area_id", using: :btree
  add_index "invites", ["event_id"], name: "index_invites_on_event_id", using: :btree
  add_index "invites", ["venue_id"], name: "index_invites_on_venue_id", using: :btree

  create_table "kpi_reports", force: :cascade do |t|
    t.integer  "company_user_id"
    t.text     "params"
    t.string   "aasm_state",        limit: 255
    t.integer  "progress"
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "kpis", force: :cascade do |t|
    t.string   "name",              limit: 255
    t.text     "description"
    t.string   "kpi_type",          limit: 255
    t.string   "capture_mechanism", limit: 255
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
    t.string   "module",            limit: 255, default: "custom", null: false
    t.integer  "ordering"
  end

  create_table "kpis_segments", force: :cascade do |t|
    t.integer  "kpi_id"
    t.string   "text",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.integer  "ordering"
  end

  add_index "kpis_segments", ["kpi_id"], name: "index_kpis_segments_on_kpi_id", using: :btree

  create_table "list_exports", force: :cascade do |t|
    t.text     "params"
    t.string   "export_format",     limit: 255
    t.string   "aasm_state",        limit: 255
    t.string   "file_file_name",    limit: 255
    t.string   "file_content_type", limit: 255
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "company_user_id"
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.string   "controller",        limit: 255
    t.integer  "progress",                      default: 0
    t.text     "url_options"
  end

  add_index "list_exports", ["company_user_id"], name: "index_list_exports_on_user_id", using: :btree

  create_table "locations", force: :cascade do |t|
    t.string "path", limit: 500
  end

  add_index "locations", ["path"], name: "index_locations_on_path", unique: true, using: :btree

  create_table "locations_places", force: :cascade do |t|
    t.integer "location_id"
    t.integer "place_id"
  end

  create_table "marques", force: :cascade do |t|
    t.integer  "brand_id"
    t.string   "name",       limit: 255
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "marques", ["brand_id"], name: "index_marques_on_brand_id", using: :btree

  create_table "memberships", force: :cascade do |t|
    t.integer  "company_user_id"
    t.integer  "memberable_id"
    t.string   "memberable_type", limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "parent_id"
    t.string   "parent_type",     limit: 255
  end

  add_index "memberships", ["company_user_id"], name: "index_memberships_on_company_user_id", using: :btree
  add_index "memberships", ["memberable_id", "memberable_type"], name: "index_memberships_on_memberable_id_and_memberable_type", using: :btree
  add_index "memberships", ["parent_id", "parent_type"], name: "index_memberships_on_parent_id_and_parent_type", using: :btree

  create_table "neighborhoods", primary_key: "gid", force: :cascade do |t|
    t.string    "state",    limit: 2
    t.string    "county",   limit: 43
    t.string    "city",     limit: 64
    t.string    "name",     limit: 64
    t.decimal   "regionid"
    t.geography "geog",     limit: {:srid=>4326, :type=>"multi_polygon", :geographic=>true}
  end

  add_index "neighborhoods", ["geog"], name: "index_neighborhoods_on_geog", using: :gist

  create_table "notifications", force: :cascade do |t|
    t.integer  "company_user_id"
    t.string   "message",         limit: 255
    t.string   "level",           limit: 255
    t.text     "path"
    t.string   "icon",            limit: 255
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.text     "message_params"
    t.text     "extra_params"
    t.hstore   "params"
  end

  add_index "notifications", ["company_user_id"], name: "index_notifications_on_company_user_id", using: :btree
  add_index "notifications", ["message"], name: "index_notifications_on_message", using: :btree
  add_index "notifications", ["params"], name: "index_notifications_on_params", using: :gist

  create_table "permissions", force: :cascade do |t|
    t.integer "role_id"
    t.string  "action",        limit: 255
    t.string  "subject_class", limit: 255
    t.string  "subject_id",    limit: 255
    t.string  "mode",          limit: 255, default: "none"
  end

  create_table "placeables", force: :cascade do |t|
    t.integer "place_id"
    t.integer "placeable_id"
    t.string  "placeable_type", limit: 255
  end

  add_index "placeables", ["place_id"], name: "index_placeables_on_place_id", using: :btree
  add_index "placeables", ["placeable_id", "placeable_type"], name: "index_placeables_on_placeable_id_and_placeable_type", using: :btree

  create_table "places", force: :cascade do |t|
    t.string    "name",                   limit: 255
    t.string    "reference",              limit: 400
    t.string    "place_id",               limit: 200
    t.string    "types_old",              limit: 255
    t.string    "formatted_address",      limit: 255
    t.string    "street_number",          limit: 255
    t.string    "route",                  limit: 255
    t.string    "zipcode",                limit: 255
    t.string    "city",                   limit: 255
    t.string    "state",                  limit: 255
    t.string    "country",                limit: 255
    t.datetime  "created_at",                                                                      null: false
    t.datetime  "updated_at",                                                                      null: false
    t.string    "administrative_level_1", limit: 255
    t.string    "administrative_level_2", limit: 255
    t.string    "td_linx_code",           limit: 255
    t.integer   "location_id"
    t.boolean   "is_location"
    t.integer   "price_level"
    t.string    "phone_number",           limit: 255
    t.string    "neighborhoods",          limit: 255,                                                           array: true
    t.geography "lonlat",                 limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.integer   "td_linx_confidence"
    t.integer   "merged_with_place_id"
    t.string    "types",                  limit: 255,                                                           array: true
  end

  add_index "places", ["city"], name: "index_places_on_city", using: :btree
  add_index "places", ["country"], name: "index_places_on_country", using: :btree
  add_index "places", ["name"], name: "index_places_on_name", using: :btree
  add_index "places", ["reference"], name: "index_places_on_reference", using: :btree
  add_index "places", ["state"], name: "index_places_on_state", using: :btree

  create_table "read_marks", force: :cascade do |t|
    t.integer  "readable_id"
    t.integer  "user_id",                  null: false
    t.string   "readable_type", limit: 20, null: false
    t.datetime "timestamp"
  end

  add_index "read_marks", ["user_id", "readable_type", "readable_id"], name: "index_read_marks_on_user_id_and_readable_type_and_readable_id", using: :btree

  create_table "report_sharings", force: :cascade do |t|
    t.integer "report_id"
    t.integer "shared_with_id"
    t.string  "shared_with_type", limit: 255
  end

  add_index "report_sharings", ["shared_with_id", "shared_with_type"], name: "index_report_sharings_on_shared_with_id_and_shared_with_type", using: :btree

  create_table "reports", force: :cascade do |t|
    t.integer "company_id"
    t.string  "name",          limit: 255
    t.text    "description"
    t.boolean "active",                    default: true
    t.integer "created_by_id"
    t.integer "updated_by_id"
    t.text    "rows"
    t.text    "columns"
    t.text    "values"
    t.text    "filters"
    t.string  "sharing",       limit: 255, default: "owner"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.datetime "created_at",                                null: false
    t.datetime "updated_at",                                null: false
    t.integer  "company_id"
    t.boolean  "active",                    default: true
    t.text     "description"
    t.boolean  "is_admin",                  default: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
  end

  create_table "satisfaction_surveys", force: :cascade do |t|
    t.integer  "company_user_id"
    t.string   "session_id",      limit: 255
    t.string   "rating",          limit: 255
    t.text     "feedback"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "satisfaction_surveys", ["company_user_id"], name: "index_satisfaction_surveys_on_company_user_id", using: :btree

  create_table "sessions", force: :cascade do |t|
    t.string   "session_id", limit: 255, null: false
    t.text     "data"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "sessions", ["session_id"], name: "index_sessions_on_session_id", using: :btree
  add_index "sessions", ["updated_at"], name: "index_sessions_on_updated_at", using: :btree

  create_table "surveys", force: :cascade do |t|
    t.integer  "event_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "active",        default: true
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "surveys", ["event_id"], name: "index_surveys_on_event_id", using: :btree

  create_table "surveys_answers", force: :cascade do |t|
    t.integer  "survey_id"
    t.integer  "kpi_id"
    t.integer  "question_id"
    t.integer  "brand_id"
    t.text     "answer"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
  end

  create_table "tasks", force: :cascade do |t|
    t.integer  "event_id"
    t.string   "title",           limit: 255
    t.datetime "due_at"
    t.boolean  "completed",                   default: false
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "active",                      default: true
    t.integer  "company_user_id"
  end

  add_index "tasks", ["company_user_id"], name: "index_tasks_on_company_user_id", using: :btree
  add_index "tasks", ["event_id"], name: "index_tasks_on_event_id", using: :btree

  create_table "tdlinx_codes", id: false, force: :cascade do |t|
    t.string "td_linx_code"
    t.string "name"
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zipcode"
  end

  add_index "tdlinx_codes", ["name"], name: "td_linx_full_name_trgm_idx", using: :gist
  add_index "tdlinx_codes", ["state"], name: "td_linx_code_state_idx", using: :btree
  add_index "tdlinx_codes", ["street"], name: "td_linx_full_street_trgm_idx", using: :gist

  create_table "teamings", force: :cascade do |t|
    t.integer "team_id"
    t.integer "teamable_id"
    t.string  "teamable_type", limit: 255
  end

  add_index "teamings", ["team_id", "teamable_id", "teamable_type"], name: "index_teamings_on_team_id_and_teamable_id_and_teamable_type", unique: true, using: :btree
  add_index "teamings", ["team_id"], name: "index_teamings_on_team_id", using: :btree
  add_index "teamings", ["teamable_id", "teamable_type"], name: "index_teamings_on_teamable_id_and_teamable_type", using: :btree

  create_table "teams", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.text     "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                               null: false
    t.datetime "updated_at",                               null: false
    t.boolean  "active",                    default: true
    t.integer  "company_id"
  end

  add_index "teams", ["company_id"], name: "index_teams_on_company_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "first_name",                limit: 255
    t.string   "last_name",                 limit: 255
    t.string   "email",                     limit: 255, default: "", null: false
    t.string   "encrypted_password",        limit: 255, default: ""
    t.string   "reset_password_token",      limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                         default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",        limit: 255
    t.string   "last_sign_in_ip",           limit: 255
    t.string   "confirmation_token",        limit: 255
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email",         limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.string   "country",                   limit: 4
    t.string   "state",                     limit: 255
    t.string   "city",                      limit: 255
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "invitation_token",          limit: 255
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type",           limit: 255
    t.integer  "current_company_id"
    t.string   "time_zone",                 limit: 255
    t.string   "detected_time_zone",        limit: 255
    t.string   "phone_number",              limit: 255
    t.string   "street_address",            limit: 255
    t.string   "unit_number",               limit: 255
    t.string   "zip_code",                  limit: 255
    t.string   "authentication_token",      limit: 255
    t.datetime "invitation_created_at"
    t.string   "avatar_file_name",          limit: 255
    t.string   "avatar_content_type",       limit: 255
    t.integer  "avatar_file_size"
    t.datetime "avatar_updated_at"
    t.boolean  "phone_number_verified"
    t.string   "phone_number_verification", limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["invitation_token"], name: "index_users_on_invitation_token", unique: true, using: :btree
  add_index "users", ["invited_by_id"], name: "index_users_on_invited_by_id", using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "venues", force: :cascade do |t|
    t.integer  "company_id"
    t.integer  "place_id"
    t.integer  "events_count"
    t.decimal  "promo_hours",                      precision: 8,  scale: 2, default: 0.0
    t.integer  "impressions"
    t.integer  "interactions"
    t.integer  "sampled"
    t.decimal  "spent",                            precision: 10, scale: 2, default: 0.0
    t.integer  "score"
    t.decimal  "avg_impressions",                  precision: 8,  scale: 2, default: 0.0
    t.datetime "created_at",                                                                null: false
    t.datetime "updated_at",                                                                null: false
    t.decimal  "avg_impressions_hour",             precision: 6,  scale: 2, default: 0.0
    t.decimal  "avg_impressions_cost",             precision: 8,  scale: 2, default: 0.0
    t.integer  "score_impressions"
    t.integer  "score_cost"
    t.boolean  "score_dirty",                                               default: false
    t.boolean  "jameson_locals",                                            default: false
    t.boolean  "top_venue",                                                 default: false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "web_address",          limit: 255
    t.integer  "place_price_level"
    t.string   "phone_number",         limit: 255
  end

  add_index "venues", ["company_id", "place_id"], name: "index_venues_on_company_id_and_place_id", unique: true, using: :btree
  add_index "venues", ["company_id"], name: "index_venues_on_company_id", using: :btree
  add_index "venues", ["place_id"], name: "index_venues_on_place_id", using: :btree

  create_table "version_associations", force: :cascade do |t|
    t.integer "version_id"
    t.string  "foreign_key_name", limit: 255, null: false
    t.integer "foreign_key_id"
  end

  add_index "version_associations", ["foreign_key_name", "foreign_key_id"], name: "index_version_associations_on_foreign_key", using: :btree
  add_index "version_associations", ["version_id"], name: "index_version_associations_on_version_id", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",      limit: 255, null: false
    t.integer  "item_id",                    null: false
    t.string   "event",          limit: 255, null: false
    t.string   "ip",             limit: 255
    t.string   "user_agent",     limit: 255
    t.string   "whodunnit",      limit: 255
    t.text     "object"
    t.datetime "created_at"
    t.integer  "transaction_id"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree
  add_index "versions", ["transaction_id"], name: "index_versions_on_transaction_id", using: :btree

  create_table "views_for_data_extracts", force: :cascade do |t|
  end

  create_table "zipcode_locations", force: :cascade do |t|
    t.string    "zipcode",         limit: 255,                                              null: false
    t.geography "lonlat",          limit: {:srid=>4326, :type=>"point", :geographic=>true}
    t.integer   "neighborhood_id"
  end

end
