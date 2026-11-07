# frozen_string_literal: true

require "skyward/core"
require "zeitwerk"
require_relative "orm/version"

loader = Zeitwerk::Loader.for_gem_extension(Skyward)
loader.inflector.inflect("orm" => "ORM")
loader.setup
