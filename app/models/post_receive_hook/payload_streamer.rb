class PostReceiveHook::PayloadStreamer
  attr_accessor :payloads, :hooks, :failures

  def initialize(payloads, hooks)
    self.payloads = payloads
    self.hooks = hooks
    self.failures = []
  end

  def outro
    "Thanks for using Redmine Git Server\n"
  end

  def failure_boundary
    "\n*** WARNING ***\n\n"
  end

  def failures_display
    failure_boundary +
    "The following hooks had errors:\n" +
    failures.uniq.map { |f| "\t#{f.name} (#{f.url}) - errors: #{failures.count(f)}\n" }.join +
    "\nDon't panic - your code is fine.\n\n"
  end

  def each
    yield "Beginning post-receive hooks...\n" if payloads.any? && hooks.any?
    payloads.each_with_index do |payload, payload_index|
      yield "Delivering hooks payload #{payload_index + 1} of #{payloads.length}...\n"
      hooks.find_each do |hook|
        begin
          yield "\tPOSTing to hook #{hook.name} - #{hook.url}... "
          hook.deliver_payload payload
          yield "success!\n"
        rescue PostReceiveHook::HookError => error
          yield "\n\n*** Oops! The hook named #{hook.name} failed: #{error.message}\n\n"
          failures << hook
        end
      end
      yield "Delivered payload #{payload_index + 1} of #{payloads.length}\n"
    end
    yield failures_display if failures.any?
    yield outro
  end
end