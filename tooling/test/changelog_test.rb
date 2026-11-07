# frozen_string_literal: true

require "date"
require "test_helper"
require "changelog"

describe Changelog do
  let(:date) { Date.new(2026, 11, 7) }

  describe ".section" do
    it "groups entries by gem, with changes to every gem first" do
      subjects = ["feat(orm): add joins (#4)", "fix(api): limit body size (#3)", "fix(deps): update zeitwerk (#2)"]

      assert_equal <<~MARKDOWN, Changelog.section("0.2.0", date, subjects)
        ## 0.2.0 (2026-11-07)

        ### All gems

        - update zeitwerk (#2)

        ### skyward-api

        - limit body size (#3)

        ### skyward-orm

        - add joins (#4)
      MARKDOWN
    end

    it "says so when no commit changes the gems" do
      section = Changelog.section("0.1.1", date, ["chore: tidy CI"])

      assert_equal "## 0.1.1 (2026-11-07)\n\nNo changes to the gems.\n", section
    end
  end

  describe ".entry" do
    it "files a scoped change under its gem" do
      assert_equal Changelog::Entry.new(gem: "skyward-core", text: "add the command registry"),
                   Changelog.entry("feat(core): add the command registry")
    end

    it "files a change with another scope under every gem" do
      assert_equal "All gems", Changelog.entry("fix(deps): update rack").gem
    end

    it "files an unscoped change under every gem" do
      assert_equal "All gems", Changelog.entry("perf: cache signatures").gem
    end

    it "marks a breaking change" do
      assert_equal "**Breaking:** rename Skyward.app", Changelog.entry("refactor(api)!: rename Skyward.app").text
    end

    it "skips a type users don't notice" do
      assert_nil Changelog.entry("chore(api): tidy")
    end

    it "skips a subject that isn't a Conventional Commit" do
      assert_nil Changelog.entry("Merge branch main")
    end
  end

  describe ".prepend" do
    it "puts the section above every earlier one" do
      assert_equal "# Changelog\n\n## 0.2.0\n\n## 0.1.0\n", Changelog.prepend("# Changelog\n\n## 0.1.0\n", "## 0.2.0\n")
    end

    it "starts the changelog when there's no earlier section" do
      assert_equal "# Changelog\n\n## 0.1.0\n", Changelog.prepend("# Changelog\n", "## 0.1.0\n")
    end
  end
end
