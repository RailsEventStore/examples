class LogVisitsByIp < ApplicationJob
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    ip = event.metadata.fetch(:request_ip)
    stream = "$by_request_IP_"+ip
    event_store.link(event.event_id, stream_name: stream)
  end
end
