class TenantsController < ApplicationController
  Visit = Data.define(:timestamp, :url, :shard)

  def show
    ActiveRecord::Base.connected_to(role: :reading, shard: :default) do
      @tenant = Tenant.find_by(host: request.host)
    end
    render :invalid and return unless @tenant

    @visits = Rails.configuration.event_store.read.of_type([ VisitRegistered ]).backward.limit(10).map do |fact|
      Visit.new(
        timestamp: fact.timestamp,
        url: [ ruby_event_store_browser_app_path, "events", fact.event_id ].join("/"),
        shard: fact.metadata[:shard]
      )
    end
  end

  def create
    Rails.configuration.event_store.publish(VisitRegistered.new(data: { host: request.host }))
    redirect_to root_path
  end
end
