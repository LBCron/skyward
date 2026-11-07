# frozen_string_literal: true

# The Skyward gems release in lockstep, so the version in each gem's
# version.rb is always the same.
module Release
  extend self

  VERSION_FILES = %w[
    skyward-core/lib/skyward/core/version.rb
    skyward-api/lib/skyward/api/version.rb
    skyward-orm/lib/skyward/orm/version.rb
    skyward/lib/skyward/version.rb
  ].freeze

  ASSIGNMENT = /VERSION = "([^"]*)"/
  # RubyGems spells a prerelease with a dot: 1.2.0.rc1.
  FORMAT = /\A\d+\.\d+\.\d+(?:\.[0-9A-Za-z]+)*\z/

  def valid?(version) = FORMAT.match?(version)

  def version(source) = source[ASSIGNMENT, 1]

  def bump(source, version) = source.sub(ASSIGNMENT, %(VERSION = "#{version}"))

  # The version every source agrees on, or nil when they disagree.
  def shared(sources)
    versions = sources.map { |source| version(source) }.uniq
    versions.first if versions.size == 1
  end
end
