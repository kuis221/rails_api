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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140405221112) do

  create_table "active_admin_comments", :force => true do |t|
    t.string   "resource_id",   :null => false
    t.string   "resource_type", :null => false
    t.integer  "author_id"
    t.string   "author_type"
    t.text     "body"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.string   "namespace"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], :name => "index_active_admin_comments_on_author_type_and_author_id"
  add_index "active_admin_comments", ["namespace"], :name => "index_active_admin_comments_on_namespace"
  add_index "active_admin_comments", ["resource_type", "resource_id"], :name => "index_admin_notes_on_resource_type_and_resource_id"

  create_table "activities", :force => true do |t|
    t.integer  "activity_type_id"
    t.integer  "activitable_id"
    t.string   "activitable_type"
    t.integer  "campaign_id"
    t.boolean  "active",           :default => true
    t.integer  "company_user_id"
    t.datetime "activity_date"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
  end

  add_index "activities", ["activitable_id", "activitable_type"], :name => "index_activities_on_activitable_id_and_activitable_type"
  add_index "activities", ["activity_type_id"], :name => "index_activities_on_activity_type_id"
  add_index "activities", ["company_user_id"], :name => "index_activities_on_company_user_id"

  create_table "activity_results", :force => true do |t|
    t.integer  "activity_id"
    t.integer  "form_field_id"
    t.text     "value"
    t.datetime "created_at",           :null => false
    t.datetime "updated_at",           :null => false
    t.integer  "form_field_option_id"
  end

  add_index "activity_results", ["activity_id", "form_field_id"], :name => "index_activity_results_on_activity_id_and_form_field_id"
  add_index "activity_results", ["activity_id"], :name => "index_activity_results_on_activity_id"
  add_index "activity_results", ["form_field_id"], :name => "index_activity_results_on_form_field_id"
  add_index "activity_results", ["form_field_option_id"], :name => "index_activity_results_on_form_field_option_id"

  create_table "activity_type_campaigns", :force => true do |t|
    t.integer  "activity_type_id"
    t.integer  "campaign_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "activity_type_campaigns", ["activity_type_id"], :name => "index_activity_type_campaigns_on_activity_type_id"
  add_index "activity_type_campaigns", ["campaign_id"], :name => "index_activity_type_campaigns_on_campaign_id"

  create_table "activity_types", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "active",      :default => true
    t.integer  "company_id"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
  end

  add_index "activity_types", ["company_id"], :name => "index_activity_types_on_company_id"

  create_table "admin_users", :force => true do |t|
    t.string   "email",                  :default => "", :null => false
    t.string   "encrypted_password",     :default => "", :null => false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                             :null => false
    t.datetime "updated_at",                             :null => false
  end

  add_index "admin_users", ["email"], :name => "index_admin_users_on_email", :unique => true
  add_index "admin_users", ["reset_password_token"], :name => "index_admin_users_on_reset_password_token", :unique => true

  create_table "areas", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "active",              :default => true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.text     "common_denominators"
  end

  add_index "areas", ["company_id"], :name => "index_areas_on_company_id"

  create_table "areas_campaigns", :force => true do |t|
    t.integer "area_id"
    t.integer "campaign_id"
  end

  create_table "asset_downloads", :force => true do |t|
    t.string   "uid"
    t.text     "assets_ids"
    t.string   "aasm_state"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "user_id"
    t.datetime "last_downloaded"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  add_index "asset_downloads", ["user_id"], :name => "index_asset_downloads_on_user_id"

  create_table "attached_assets", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "asset_type"
    t.integer  "attachable_id"
    t.string   "attachable_type"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
    t.boolean  "active",            :default => true
    t.string   "direct_upload_url"
    t.boolean  "processed",         :default => false, :null => false
    t.integer  "rating",            :default => 0
  end

  add_index "attached_assets", ["attachable_type", "attachable_id"], :name => "index_attached_assets_on_attachable_type_and_attachable_id"

  create_table "brand_portfolios", :force => true do |t|
    t.string   "name"
    t.boolean  "active",        :default => true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.text     "description"
  end

  add_index "brand_portfolios", ["company_id"], :name => "index_brand_portfolios_on_company_id"

  create_table "brand_portfolios_brands", :force => true do |t|
    t.integer "brand_id"
    t.integer "brand_portfolio_id"
  end

  add_index "brand_portfolios_brands", ["brand_id", "brand_portfolio_id"], :name => "brand_portfolio_unique_idx", :unique => true
  add_index "brand_portfolios_brands", ["brand_id"], :name => "index_brand_portfolios_brands_on_brand_id"
  add_index "brand_portfolios_brands", ["brand_portfolio_id"], :name => "index_brand_portfolios_brands_on_brand_portfolio_id"

  create_table "brand_portfolios_campaigns", :force => true do |t|
    t.integer "brand_portfolio_id"
    t.integer "campaign_id"
  end

  add_index "brand_portfolios_campaigns", ["brand_portfolio_id"], :name => "index_brand_portfolios_campaigns_on_brand_portfolio_id"
  add_index "brand_portfolios_campaigns", ["campaign_id"], :name => "index_brand_portfolios_campaigns_on_campaign_id"

  create_table "brands", :force => true do |t|
    t.string   "name"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  create_table "brands_campaigns", :force => true do |t|
    t.integer "brand_id"
    t.integer "campaign_id"
  end

  add_index "brands_campaigns", ["brand_id"], :name => "index_brands_campaigns_on_brand_id"
  add_index "brands_campaigns", ["campaign_id"], :name => "index_brands_campaigns_on_campaign_id"

  create_table "campaign_form_fields", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "kpi_id"
    t.integer  "ordering"
    t.string   "name"
    t.string   "field_type"
    t.text     "options"
    t.integer  "section_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  add_index "campaign_form_fields", ["campaign_id"], :name => "index_campaign_form_fields_on_campaign_id"
  add_index "campaign_form_fields", ["kpi_id"], :name => "index_campaign_form_fields_on_kpi_id"

  create_table "campaigns", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "aasm_state"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "company_id"
    t.integer  "first_event_id"
    t.integer  "last_event_id"
    t.datetime "first_event_at"
    t.datetime "last_event_at"
    t.date     "start_date"
    t.date     "end_date"
  end

  add_index "campaigns", ["company_id"], :name => "index_campaigns_on_company_id"

  create_table "campaigns_date_ranges", :force => true do |t|
    t.integer "campaign_id"
    t.integer "date_range_id"
  end

  create_table "campaigns_day_parts", :force => true do |t|
    t.integer "campaign_id"
    t.integer "day_part_id"
  end

  create_table "campaigns_teams", :force => true do |t|
    t.integer "campaign_id"
    t.integer "team_id"
  end

  add_index "campaigns_teams", ["campaign_id"], :name => "index_campaigns_teams_on_campaign_id"
  add_index "campaigns_teams", ["team_id"], :name => "index_campaigns_teams_on_team_id"

  create_table "comments", :force => true do |t|
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.text     "content"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "comments", ["commentable_type", "commentable_id"], :name => "index_comments_on_commentable_type_and_commentable_id"
  add_index "comments", ["created_at"], :name => "index_comments_on_created_at"

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.boolean  "timezone_support"
  end

  create_table "company_users", :force => true do |t|
    t.integer  "company_id"
    t.integer  "user_id"
    t.integer  "role_id"
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.boolean  "active",           :default => true
    t.datetime "last_activity_at"
  end

  add_index "company_users", ["company_id"], :name => "index_company_users_on_company_id"
  add_index "company_users", ["user_id"], :name => "index_company_users_on_user_id"

  create_table "contact_events", :force => true do |t|
    t.integer  "event_id"
    t.integer  "contactable_id"
    t.string   "contactable_type"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
  end

  add_index "contact_events", ["contactable_id", "contactable_type"], :name => "index_contact_events_on_contactable_id_and_contactable_type"
  add_index "contact_events", ["event_id"], :name => "index_contact_events_on_event_id"

  create_table "contacts", :force => true do |t|
    t.integer  "company_id"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "title"
    t.string   "email"
    t.string   "phone_number"
    t.string   "street1"
    t.string   "street2"
    t.string   "country"
    t.string   "state"
    t.string   "city"
    t.string   "zip_code"
    t.datetime "created_at",   :null => false
    t.datetime "updated_at",   :null => false
  end

  create_table "data_migrations", :force => true do |t|
    t.integer  "remote_id"
    t.string   "remote_type"
    t.integer  "local_id"
    t.string   "local_type"
    t.integer  "company_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "date_items", :force => true do |t|
    t.integer  "date_range_id"
    t.date     "start_date"
    t.date     "end_date"
    t.boolean  "recurrence",        :default => false
    t.string   "recurrence_type"
    t.integer  "recurrence_period"
    t.string   "recurrence_days"
    t.datetime "created_at",                           :null => false
    t.datetime "updated_at",                           :null => false
  end

  create_table "date_ranges", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "active",        :default => true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "day_items", :force => true do |t|
    t.integer  "day_part_id"
    t.time     "start_time"
    t.time     "end_time"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "day_parts", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.boolean  "active",        :default => true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  create_table "delayed_jobs", :force => true do |t|
    t.integer  "priority",   :default => 0, :null => false
    t.integer  "attempts",   :default => 0, :null => false
    t.text     "handler",                   :null => false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  add_index "delayed_jobs", ["priority", "run_at"], :name => "delayed_jobs_priority"

  create_table "event_data", :force => true do |t|
    t.integer  "event_id"
    t.integer  "impressions",                                              :default => 0
    t.integer  "interactions",                                             :default => 0
    t.integer  "samples",                                                  :default => 0
    t.decimal  "gender_female",             :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "gender_male",               :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "ethnicity_asian",           :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "ethnicity_black",           :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "ethnicity_hispanic",        :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "ethnicity_native_american", :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "ethnicity_white",           :precision => 5,  :scale => 2, :default => 0.0
    t.decimal  "spent",                     :precision => 10, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
  end

  add_index "event_data", ["event_id"], :name => "index_event_data_on_event_id"

  create_table "event_expenses", :force => true do |t|
    t.integer  "event_id"
    t.string   "name"
    t.decimal  "amount",        :precision => 9, :scale => 2, :default => 0.0
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                                   :null => false
    t.datetime "updated_at",                                                   :null => false
  end

  add_index "event_expenses", ["event_id"], :name => "index_event_expenses_on_event_id"

  create_table "event_results", :force => true do |t|
    t.integer  "form_field_id"
    t.integer  "event_id"
    t.integer  "kpis_segment_id"
    t.text     "value"
    t.decimal  "scalar_value",    :precision => 10, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                      :null => false
    t.datetime "updated_at",                                                      :null => false
    t.integer  "kpi_id"
  end

  add_index "event_results", ["event_id", "form_field_id"], :name => "index_event_results_on_event_id_and_form_field_id"
  add_index "event_results", ["event_id"], :name => "index_event_results_on_event_id"
  add_index "event_results", ["form_field_id"], :name => "index_event_results_on_form_field_id"
  add_index "event_results", ["kpi_id"], :name => "index_event_results_on_kpi_id"

  create_table "events", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "company_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "aasm_state"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
    t.boolean  "active",                                       :default => true
    t.integer  "place_id"
    t.decimal  "promo_hours",    :precision => 6, :scale => 2, :default => 0.0
    t.text     "reject_reason"
    t.text     "summary"
    t.string   "timezone"
    t.datetime "local_start_at"
    t.datetime "local_end_at"
  end

  add_index "events", ["campaign_id"], :name => "index_events_on_campaign_id"
  add_index "events", ["place_id"], :name => "index_events_on_place_id"

  create_table "form_field_options", :force => true do |t|
    t.integer  "form_field_id"
    t.string   "name"
    t.integer  "ordering"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
  end

  add_index "form_field_options", ["form_field_id"], :name => "index_form_field_options_on_form_field_id"

  create_table "form_fields", :force => true do |t|
    t.integer  "fieldable_id"
    t.string   "fieldable_type"
    t.string   "name"
    t.string   "type"
    t.text     "settings"
    t.integer  "ordering"
    t.boolean  "required"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
  end

  add_index "form_fields", ["fieldable_id", "fieldable_type"], :name => "index_form_fields_on_fieldable_id_and_fieldable_type"

  create_table "goals", :force => true do |t|
    t.integer  "kpi_id"
    t.integer  "kpis_segment_id"
    t.decimal  "value"
    t.datetime "created_at",       :null => false
    t.datetime "updated_at",       :null => false
    t.integer  "goalable_id"
    t.string   "goalable_type"
    t.integer  "parent_id"
    t.string   "parent_type"
    t.string   "title"
    t.date     "start_date"
    t.date     "due_date"
    t.integer  "activity_type_id"
  end

  add_index "goals", ["goalable_id", "goalable_type"], :name => "index_goals_on_goalable_id_and_goalable_type"
  add_index "goals", ["kpi_id"], :name => "index_goals_on_kpi_id"
  add_index "goals", ["kpis_segment_id"], :name => "index_goals_on_kpis_segment_id"

  create_table "kpi_reports", :force => true do |t|
    t.integer  "company_user_id"
    t.text     "params"
    t.string   "aasm_state"
    t.integer  "progress"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "kpis", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.string   "kpi_type"
    t.string   "capture_mechanism"
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                              :null => false
    t.datetime "updated_at",                              :null => false
    t.string   "module",            :default => "custom", :null => false
    t.integer  "ordering"
  end

  create_table "kpis_segments", :force => true do |t|
    t.integer  "kpi_id"
    t.string   "text"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
    t.integer  "ordering"
  end

  add_index "kpis_segments", ["kpi_id"], :name => "index_kpis_segments_on_kpi_id"

  create_table "list_exports", :force => true do |t|
    t.text     "params"
    t.string   "export_format"
    t.string   "aasm_state"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "company_user_id"
    t.datetime "created_at",                       :null => false
    t.datetime "updated_at",                       :null => false
    t.string   "controller"
    t.integer  "progress",          :default => 0
  end

  add_index "list_exports", ["company_user_id"], :name => "index_list_exports_on_user_id"

  create_table "locations", :force => true do |t|
    t.string "path", :limit => 500
  end

  add_index "locations", ["path"], :name => "index_locations_on_path", :unique => true

  create_table "locations_places", :force => true do |t|
    t.integer "location_id"
    t.integer "place_id"
  end

  create_table "marques", :force => true do |t|
    t.integer  "brand_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "marques", ["brand_id"], :name => "index_marques_on_brand_id"

  create_table "memberships", :force => true do |t|
    t.integer  "company_user_id"
    t.integer  "memberable_id"
    t.string   "memberable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.integer  "parent_id"
    t.string   "parent_type"
  end

  add_index "memberships", ["company_user_id"], :name => "index_memberships_on_company_user_id"
  add_index "memberships", ["memberable_id", "memberable_type"], :name => "index_memberships_on_memberable_id_and_memberable_type"
  add_index "memberships", ["parent_id", "parent_type"], :name => "index_memberships_on_parent_id_and_parent_type"

  create_table "notifications", :force => true do |t|
    t.integer  "company_user_id"
    t.string   "message"
    t.string   "level"
    t.text     "path"
    t.string   "icon"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
    t.text     "message_params"
    t.text     "extra_params"
  end

  add_index "notifications", ["company_user_id"], :name => "index_notifications_on_company_user_id"

  create_table "permissions", :force => true do |t|
    t.integer "role_id"
    t.string  "action"
    t.string  "subject_class"
    t.string  "subject_id"
  end

  create_table "placeables", :force => true do |t|
    t.integer "place_id"
    t.integer "placeable_id"
    t.string  "placeable_type"
  end

  add_index "placeables", ["place_id"], :name => "index_placeables_on_place_id"
  add_index "placeables", ["placeable_id", "placeable_type"], :name => "index_placeables_on_placeable_id_and_placeable_type"

  create_table "places", :force => true do |t|
    t.string   "name"
    t.string   "reference",              :limit => 400
    t.string   "place_id",               :limit => 100
    t.string   "types"
    t.string   "formatted_address"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "street_number"
    t.string   "route"
    t.string   "zipcode"
    t.string   "city"
    t.string   "state"
    t.string   "country"
    t.datetime "created_at",                            :null => false
    t.datetime "updated_at",                            :null => false
    t.string   "administrative_level_1"
    t.string   "administrative_level_2"
    t.string   "td_linx_code"
    t.string   "neighborhood"
    t.integer  "location_id"
    t.boolean  "is_location"
  end

  add_index "places", ["reference"], :name => "index_places_on_reference"

  create_table "read_marks", :force => true do |t|
    t.integer  "readable_id"
    t.integer  "user_id",                     :null => false
    t.string   "readable_type", :limit => 20, :null => false
    t.datetime "timestamp"
  end

  add_index "read_marks", ["user_id", "readable_type", "readable_id"], :name => "index_read_marks_on_user_id_and_readable_type_and_readable_id"

  create_table "reports", :id => false, :force => true do |t|
    t.integer  "id",                :null => false
    t.string   "type"
    t.integer  "company_user_id"
    t.text     "params"
    t.string   "aasm_state"
    t.integer  "progress"
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "created_at",        :null => false
    t.datetime "updated_at",        :null => false
  end

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                     :null => false
    t.datetime "updated_at",                     :null => false
    t.integer  "company_id"
    t.boolean  "active",      :default => true
    t.text     "description"
    t.boolean  "is_admin",    :default => false
  end

  create_table "surveys", :force => true do |t|
    t.integer  "event_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "active",        :default => true
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "surveys", ["event_id"], :name => "index_surveys_on_event_id"

  create_table "surveys_answers", :force => true do |t|
    t.integer  "survey_id"
    t.integer  "kpi_id"
    t.integer  "question_id"
    t.integer  "brand_id"
    t.text     "answer"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "tasks", :force => true do |t|
    t.integer  "event_id"
    t.string   "title"
    t.datetime "due_at"
    t.boolean  "completed",       :default => false
    t.datetime "created_at",                         :null => false
    t.datetime "updated_at",                         :null => false
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.boolean  "active",          :default => true
    t.integer  "company_user_id"
  end

  add_index "tasks", ["company_user_id"], :name => "index_tasks_on_company_user_id"
  add_index "tasks", ["event_id"], :name => "index_tasks_on_event_id"

  create_table "td_linxes", :force => true do |t|
    t.string   "store_code"
    t.string   "retailer_dba_name"
    t.string   "retailer_address"
    t.string   "retailer_city"
    t.string   "retailer_state"
    t.string   "retailer_trade_channel"
    t.string   "license_type"
    t.string   "fixed_address"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
  end

  add_index "td_linxes", ["store_code"], :name => "index_td_linxes_on_store_code", :unique => true

  create_table "teamings", :force => true do |t|
    t.integer "team_id"
    t.integer "teamable_id"
    t.string  "teamable_type"
  end

  add_index "teamings", ["team_id", "teamable_id", "teamable_type"], :name => "index_teamings_on_team_id_and_teamable_id_and_teamable_type", :unique => true
  add_index "teamings", ["team_id"], :name => "index_teamings_on_team_id"
  add_index "teamings", ["teamable_id", "teamable_type"], :name => "index_teamings_on_teamable_id_and_teamable_type"

  create_table "teams", :force => true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
    t.boolean  "active",        :default => true
    t.integer  "company_id"
  end

  add_index "teams", ["company_id"], :name => "index_teams_on_company_id"

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",                  :default => ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",                                          :null => false
    t.datetime "updated_at",                                          :null => false
    t.string   "country",                :limit => 4
    t.string   "state"
    t.string   "city"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "invitation_token"
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "current_company_id"
    t.string   "time_zone"
    t.string   "detected_time_zone"
    t.string   "phone_number"
    t.string   "street_address"
    t.string   "unit_number"
    t.string   "zip_code"
    t.string   "authentication_token"
    t.datetime "invitation_created_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token", :unique => true
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "venues", :force => true do |t|
    t.integer  "company_id"
    t.integer  "place_id"
    t.integer  "events_count"
    t.decimal  "promo_hours",          :precision => 8,  :scale => 2, :default => 0.0
    t.integer  "impressions"
    t.integer  "interactions"
    t.integer  "sampled"
    t.decimal  "spent",                :precision => 10, :scale => 2, :default => 0.0
    t.integer  "score"
    t.decimal  "avg_impressions",      :precision => 8,  :scale => 2, :default => 0.0
    t.datetime "created_at",                                                           :null => false
    t.datetime "updated_at",                                                           :null => false
    t.decimal  "avg_impressions_hour", :precision => 6,  :scale => 2, :default => 0.0
    t.decimal  "avg_impressions_cost", :precision => 8,  :scale => 2, :default => 0.0
    t.integer  "score_impressions"
    t.integer  "score_cost"
  end

  add_index "venues", ["company_id", "place_id"], :name => "index_venues_on_company_id_and_place_id", :unique => true
  add_index "venues", ["company_id"], :name => "index_venues_on_company_id"
  add_index "venues", ["place_id"], :name => "index_venues_on_place_id"

end
