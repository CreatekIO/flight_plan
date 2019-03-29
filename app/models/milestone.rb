class Milestone < ApplicationRecord
  # Silence warning about overriding `open` method
  # (which is inherited from Kernel)
  logger.silence do
    permissive_enum state: { open: 'open', closed: 'closed' }
  end

  belongs_to :repo
end
