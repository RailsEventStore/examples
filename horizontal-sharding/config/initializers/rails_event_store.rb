require "rails_event_store"
require "aggregate_root"
require "arkency/command_bus"

Rails.configuration.to_prepare do
  Rails.configuration.event_store = RailsEventStore::Client.new(
    repository: RubyEventStore::ActiveRecord::EventRepository.new(
      model_factory: RubyEventStore::ActiveRecord::WithAbstractBaseClass.new(ShardRecord),
      serializer: JSON,
    ),
    dispatcher: RubyEventStore::ComposedDispatcher.new(
      RubyEventStore::ImmediateAsyncDispatcher.new(
        scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: JSON)
      ),
      RubyEventStore::Dispatcher.new
    ),
    request_metadata: ->(env) do
      request = ActionDispatch::Request.new(env)
      { remote_ip: request.remote_ip, request_id: request.uuid, shard: ShardRecord.current_shard.to_s }
    end,
  )
  Rails.configuration.command_bus = Arkency::CommandBus.new

  AggregateRoot.configure do |config|
    config.default_event_store = Rails.configuration.event_store
  end

  # Subscribe event handlers below
  Rails.configuration.event_store.tap do |store|
    store.subscribe(LogVisitsByIp, to: [ VisitRegistered ])

    store.subscribe_to_all_events(RailsEventStore::LinkByEventType.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCorrelationId.new)
    store.subscribe_to_all_events(RailsEventStore::LinkByCausationId.new)
  end
end
