# frozen_string_literal: true

# Builds CHANGELOG.md sections from squash-commit subjects, which are
# Conventional Commits whose scope names the gem they change.
module Changelog
  extend self

  HEADER = "# Changelog\n"
  # The types a gem's users notice. Any type marked breaking (`!`) is kept too.
  TYPES = %w[feat fix perf].freeze
  SCOPES = { "core" => "skyward-core", "api" => "skyward-api", "orm" => "skyward-orm", "skyward" => "skyward" }.freeze
  ACROSS = "All gems"
  ORDER = [ACROSS, *SCOPES.values].freeze
  SUBJECT = /\A(?<type>[a-z]+)(?:\((?<scope>[a-z-]+)\))?(?<breaking>!)?: (?<description>.+)\z/

  Entry = Data.define(:gem, :text)

  def section(version, date, subjects)
    entries = subjects.filter_map { |subject| entry(subject) }
    body = entries.empty? ? "No changes to the gems.\n" : grouped(entries)
    "## #{version} (#{date.iso8601})\n\n#{body}"
  end

  def entry(subject)
    match = SUBJECT.match(subject)
    return unless match
    return unless match[:breaking] || TYPES.include?(match[:type])

    text = match[:breaking] ? "**Breaking:** #{match[:description]}" : match[:description]
    Entry.new(gem: SCOPES.fetch(match[:scope], ACROSS), text:)
  end

  def prepend(changelog, section)
    rest = changelog.delete_prefix(HEADER).lstrip
    [HEADER, section, rest].reject(&:empty?).join("\n")
  end

  private

  def grouped(entries)
    entries.group_by(&:gem)
           .sort_by { |gem, _| ORDER.index(gem) }
           .map { |gem, group| "### #{gem}\n\n#{group.map { |entry| "- #{entry.text}\n" }.join}" }
           .join("\n")
  end
end
