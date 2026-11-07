# frozen_string_literal: true

require "json"

class Skyward::API::Serve::Reloader
  INTERVAL = 0.5 #: Float

  # @rbs @watch: ^() -> Hash[String, Time]
  # @rbs @load: ^() -> Skyward::API::Serve::_RackApp
  # @rbs @clock: ^() -> Float
  # @rbs @mutex: Thread::Mutex
  # @rbs @checked_at: Float
  # @rbs @files: Hash[String, Time]
  # @rbs @app: Skyward::API::Serve::_RackApp

  # @rbs watch: ^() -> Hash[String, Time]
  # @rbs load: ^() -> Skyward::API::Serve::_RackApp
  # @rbs clock: ^() -> Float
  # @rbs return: void
  def initialize(watch:, load:, clock:)
    @watch = watch
    @load = load
    @clock = clock
    @mutex = Thread::Mutex.new
    @checked_at = clock.call
    @files = watch.call
    @app = attempt
  end

  # The app is taken under the lock but called outside it, so a request in
  # flight finishes on the app it started with.
  # @rbs env: Hash[String, untyped]
  # @rbs return: untyped
  def call(env) = @mutex.synchronize { current }.call(env)

  private

  # @rbs return: Skyward::API::Serve::_RackApp
  def current
    now = @clock.call
    return @app if now - @checked_at < INTERVAL

    @checked_at = now
    files = @watch.call
    return @app if files == @files

    @files = files
    @app = attempt
  end

  # A SyntaxError or LoadError is a ScriptError, not a StandardError.
  # @rbs return: Skyward::API::Serve::_RackApp
  def attempt
    @load.call
  rescue StandardError, ScriptError => e
    ->(_env) { failure(e) } #: ^(Hash[String, untyped]) -> Skyward::API::App::response
  end

  # @rbs error: Exception
  # @rbs return: Skyward::API::App::response
  def failure(error)
    problem = {
      type: "about:blank",
      title: "Internal Server Error",
      status: 500,
      detail: "#{error.class}: #{error.message}",
      backtrace: error.backtrace
    }
    [500, { "content-type" => "application/problem+json" }, [JSON.generate(problem)]]
  end
end
