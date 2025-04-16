module ShardedHandler
  def perform(event)
    shard = event.metadata[:shard] || :default
    ActiveRecord::Base.connected_to(role: :writing, shard: shard.to_sym) do
      Rails
        .configuration
        .event_store
        .with_metadata(shard: shard) { super }
    end
  end
end
