class ShardRecord < ApplicationRecord
  self.abstract_class = true

  connects_to shards: {
    arkency: { writing: :arkency, reading: :arkency },
    railseventstore: { writing: :railseventstore, reading: :railseventstore }
  }
end
