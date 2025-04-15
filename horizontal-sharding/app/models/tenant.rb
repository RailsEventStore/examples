class Tenant < ApplicationRecord
  def shard
    self.host.split(".").first.to_sym
  end
end
