class TicketMigrator < ApplicationMigrator
  ignore_columns :state

  %i[number title body state].each do |column|
    rename :"remote_#{column}", to: column
  end
end
