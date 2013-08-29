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

ActiveRecord::Schema.define(:version => 20130829181311) do

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
    t.boolean  "active",        :default => true
    t.integer  "company_id"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                      :null => false
    t.datetime "updated_at",                      :null => false
  end

  add_index "areas", ["company_id"], :name => "index_areas_on_company_id"

  create_table "areas_places", :force => true do |t|
    t.integer "area_id"
    t.integer "place_id"
  end

  add_index "areas_places", ["area_id", "place_id"], :name => "index_areas_places_on_area_id_and_place_id", :unique => true
  add_index "areas_places", ["area_id"], :name => "index_areas_places_on_area_id"
  add_index "areas_places", ["place_id"], :name => "index_areas_places_on_place_id"

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
    t.datetime "created_at",                          :null => false
    t.datetime "updated_at",                          :null => false
    t.boolean  "active",            :default => true
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
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "company_id"
  end

  add_index "campaigns", ["company_id"], :name => "index_campaigns_on_company_id"

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

  create_table "companies", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
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

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.integer  "event_id"
  end

  add_index "documents", ["event_id"], :name => "index_documents_on_event_id"

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
    t.decimal  "cost",                      :precision => 10, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
  end

  add_index "event_data", ["event_id"], :name => "index_event_data_on_event_id"

  create_table "event_expenses", :force => true do |t|
    t.integer  "event_id"
    t.string   "name"
    t.decimal  "amount",            :precision => 9, :scale => 2, :default => 0.0
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                                       :null => false
    t.datetime "updated_at",                                                       :null => false
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

  add_index "event_results", ["kpi_id"], :name => "index_event_results_on_kpi_id"

  create_table "events", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "company_id"
    t.datetime "start_at"
    t.datetime "end_at"
    t.string   "aasm_state"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.datetime "created_at",                                                    :null => false
    t.datetime "updated_at",                                                    :null => false
    t.boolean  "active",                                      :default => true
    t.integer  "place_id"
    t.decimal  "promo_hours",   :precision => 6, :scale => 2, :default => 0.0
    t.text     "reject_reason"
    t.text     "summary"
  end

  add_index "events", ["campaign_id"], :name => "index_events_on_campaign_id"
  add_index "events", ["place_id"], :name => "index_events_on_place_id"

  create_table "goals", :force => true do |t|
    t.integer  "campaign_id"
    t.integer  "kpi_id"
    t.integer  "kpis_segment_id"
    t.decimal  "value"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "goals", ["campaign_id"], :name => "index_goals_on_campaign_id"
  add_index "goals", ["kpi_id"], :name => "index_goals_on_kpi_id"
  add_index "goals", ["kpis_segment_id"], :name => "index_goals_on_kpis_segment_id"

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
  end

  create_table "kpis_segments", :force => true do |t|
    t.integer  "kpi_id"
    t.string   "text"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "kpis_segments", ["kpi_id"], :name => "index_kpis_segments_on_kpi_id"

  create_table "memberships", :force => true do |t|
    t.integer  "company_user_id"
    t.integer  "memberable_id"
    t.string   "memberable_type"
    t.datetime "created_at",      :null => false
    t.datetime "updated_at",      :null => false
  end

  add_index "memberships", ["company_user_id"], :name => "index_memberships_on_company_user_id"
  add_index "memberships", ["memberable_id", "memberable_type"], :name => "index_memberships_on_memberable_id_and_memberable_type"

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
  end

  add_index "places", ["reference"], :name => "index_places_on_reference"

  create_table "roles", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",                    :null => false
    t.datetime "updated_at",                    :null => false
    t.text     "permissions"
    t.integer  "company_id"
    t.boolean  "active",      :default => true
    t.text     "description"
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
    t.string   "email",                                :default => "", :null => false
    t.string   "encrypted_password",                   :default => ""
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                        :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.datetime "created_at",                                           :null => false
    t.datetime "updated_at",                                           :null => false
    t.string   "country",                :limit => 4
    t.string   "state"
    t.string   "city"
    t.integer  "created_by_id"
    t.integer  "updated_by_id"
    t.string   "invitation_token",       :limit => 60
    t.datetime "invitation_sent_at"
    t.datetime "invitation_accepted_at"
    t.integer  "invitation_limit"
    t.integer  "invited_by_id"
    t.string   "invited_by_type"
    t.integer  "current_company_id"
    t.string   "time_zone"
    t.string   "detected_time_zone"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["invitation_token"], :name => "index_users_on_invitation_token", :unique => true
  add_index "users", ["invited_by_id"], :name => "index_users_on_invited_by_id"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

  create_table "venues", :force => true do |t|
    t.integer  "company_id"
    t.integer  "place_id"
    t.integer  "events"
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
