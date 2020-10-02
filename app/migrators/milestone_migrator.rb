class MilestoneMigrator < ApplicationMigrator
  rename :remote_number, to: :number
end
