class PostReceiveHook < ActiveRecord::Base
  belongs_to :repository

  attr_accessible :name, :url

  def deliver_payloads(payloads)
    payloads.each { |payload| deliver_payload payload }
  end

  def deliver_payload(payload)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    errmsg = nil
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data "payload" => payload.to_hash.to_json
    res = http.start { |s| s.request request }
    raise HookError unless res.is_a? Net::HTTPSuccess
  end

  class HookError < Exception; end
end
