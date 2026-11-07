# frozen_string_literal: true

require "zeitwerk"
require_relative "core/version"

# Skyward Core owns the Skyward namespace: its version.rb opens it, and every
# Skyward gem's loader, this one included, extends it.
loader = Zeitwerk::Loader.for_gem_extension(Skyward)
loader.setup
