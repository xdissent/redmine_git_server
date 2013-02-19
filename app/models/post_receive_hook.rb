class PostReceiveHook < ActiveRecord::Base
  belongs_to :repository

  attr_accessible :name, :url

  def deliver_payloads(payloads)
    payloads.each { |payload| deliver_payload payload }
  end

  def deliver_payload(payload)
    uri = URI(url)
    raise HookError.new self, "Invalid URI" if uri.is_a? URI::Generic
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")

    errmsg = nil
    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data "payload" => payload.to_hash.to_json
    res = http.start { |s| s.request request }
    raise HookError.new self, "Response error" unless res.is_a? Net::HTTPSuccess
  rescue SocketError, Timeout::Error, EOFError
    raise HookError.new self, "Request error"
  end

  class HookError < Exception
    attr_accessor :post_receive_hook

    def initialize(post_receive_hook, msg = nil)
      super msg
      self.post_receive_hook = post_receive_hook
    end
  end
end
