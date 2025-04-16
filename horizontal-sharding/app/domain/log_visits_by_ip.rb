class LogVisitsByIp < ApplicationJob
  prepend ShardedHandler
  prepend RailsEventStore::CorrelatedHandler
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    return if TrafficPeakDetected === event

    ip = event.metadata.fetch(:remote_ip)
    stream = "$by_request_IP_"+ip
    event_store = Rails.configuration.event_store
    event_store.link(event.event_id, stream_name: stream)

    last_peak = event_store.read.stream(stream).of_type([ TrafficPeakDetected ]).last
    recent_visits = event_store.read
      .stream(stream)
      .of_type([ VisitRegistered ])
    recent_visits = recent_visits.from(last_peak.event_id) if last_peak

    return if recent_visits.count < 10

    last_10 = event_store.read
      .stream(stream)
      .of_type([ VisitRegistered ])
      .backward
      .from(recent_visits.last.event_id)
      .limit(10)
      .to_a
    timespan = [ last_10.first, last_10.last ].map(&:timestamp).reduce(&:-)
    if timespan < 10.0
      event_store.publish(
        TrafficPeakDetected.new(data: { timespan: timespan }, metadata: { remote_ip: ip }),
        stream_name: stream
      )
    end
  end
end
