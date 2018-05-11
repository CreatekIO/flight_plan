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

ActiveRecord::Schema.define(version: 20180511135740) do

  create_table "board_repos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "board_id"
    t.bigint "repo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id"], name: "index_board_repos_on_board_id"
    t.index ["repo_id"], name: "index_board_repos_on_repo_id"
  end

  create_table "board_tickets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "board_id"
    t.bigint "ticket_id"
    t.bigint "swimlane_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id"], name: "index_board_tickets_on_board_id"
    t.index ["swimlane_id"], name: "index_board_tickets_on_swimlane_id"
    t.index ["ticket_id"], name: "index_board_tickets_on_ticket_id"
  end

  create_table "boards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "deploy_swimlane_id"
    t.boolean "auto_deploy", default: false, null: false
    t.string "additional_branches_regex"
  end

  create_table "comments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "ticket_id"
    t.text "remote_body"
    t.string "remote_id"
    t.string "remote_author_id"
    t.string "remote_author"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ticket_id"], name: "index_comments_on_ticket_id"
  end

  create_table "pull_request_connections", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "ticket_id"
    t.bigint "pull_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pull_request_id"], name: "index_pull_request_connections_on_pull_request_id"
    t.index ["ticket_id"], name: "index_pull_request_connections_on_ticket_id"
  end

  create_table "pull_requests", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.string "remote_id"
    t.string "remote_number"
    t.string "remote_title"
    t.text "remote_body"
    t.string "remote_state"
    t.string "remote_head_branch"
    t.string "remote_head_sha"
    t.string "remote_base_branch"
    t.bigint "repo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "merge_status"
    t.boolean "merged", default: false
    t.index ["merge_status"], name: "index_pull_requests_on_merge_status"
    t.index ["merged"], name: "index_pull_requests_on_merged"
    t.index ["repo_id"], name: "index_pull_requests_on_repo_id"
  end

  create_table "repo_events", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.string "type", null: false
    t.bigint "repo_id"
    t.string "remote_user_id"
    t.string "remote_username"
    t.string "record_type"
    t.bigint "record_id"
    t.string "action"
    t.string "state"
    t.string "branch"
    t.string "sha"
    t.string "url"
    t.string "context"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["action"], name: "index_repo_events_on_action"
    t.index ["id", "type"], name: "index_repo_events_on_id_and_type"
    t.index ["record_type", "record_id"], name: "index_repo_events_on_record_type_and_record_id"
    t.index ["remote_user_id"], name: "index_repo_events_on_remote_user_id"
    t.index ["repo_id"], name: "index_repo_events_on_repo_id"
    t.index ["state"], name: "index_repo_events_on_state"
  end

  create_table "repos", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.string "name"
    t.string "remote_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "swimlane_transitions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "swimlane_id"
    t.integer "transition_id"
    t.integer "position"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["swimlane_id"], name: "index_swimlane_transitions_on_swimlane_id"
  end

  create_table "swimlanes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.bigint "board_id"
    t.string "name"
    t.integer "position"
    t.boolean "display_duration"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_id"], name: "index_swimlanes_on_board_id"
  end

  create_table "tickets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.string "remote_id"
    t.string "remote_number"
    t.string "remote_title"
    t.text "remote_body"
    t.string "remote_state"
    t.string "state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "repo_id"
    t.boolean "merged", default: false
    t.index ["repo_id"], name: "index_tickets_on_repo_id"
  end

  create_table "timesheets", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "board_ticket_id"
    t.bigint "swimlane_id"
    t.bigint "before_swimlane_id"
    t.bigint "after_swimlane_id"
    t.index ["after_swimlane_id"], name: "index_timesheets_on_after_swimlane_id"
    t.index ["before_swimlane_id"], name: "index_timesheets_on_before_swimlane_id"
    t.index ["board_ticket_id"], name: "index_timesheets_on_board_ticket_id"
    t.index ["swimlane_id"], name: "index_timesheets_on_swimlane_id"
  end

  create_table "users", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin" do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "remember_created_at"
  end

  add_foreign_key "pull_request_connections", "pull_requests"
  add_foreign_key "pull_request_connections", "tickets"
  add_foreign_key "pull_requests", "repos"
  add_foreign_key "repo_events", "repos"
  add_foreign_key "tickets", "repos"
  add_foreign_key "timesheets", "swimlanes", column: "after_swimlane_id"
  add_foreign_key "timesheets", "swimlanes", column: "before_swimlane_id"
end
