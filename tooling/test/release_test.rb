# frozen_string_literal: true

require "test_helper"
require "release"

describe Release do
  let(:source) { %(module Skyward\n  VERSION = "0.1.0" #: String\nend\n) }

  describe ".valid?" do
    it "accepts a release version" do
      assert Release.valid?("1.12.0")
    end

    it "accepts a prerelease in RubyGems' dotted form" do
      assert Release.valid?("0.2.0.rc1")
    end

    it "rejects a version with a v prefix" do
      refute Release.valid?("v0.2.0")
    end

    it "rejects a version missing its patch number" do
      refute Release.valid?("0.2")
    end
  end

  describe ".version" do
    it "reads the version from a version.rb" do
      assert_equal "0.1.0", Release.version(source)
    end

    it "returns nil for a file with no version" do
      assert_nil Release.version("module Skyward\nend\n")
    end
  end

  describe ".bump" do
    it "replaces the version and keeps the rest of the file" do
      assert_equal %(module Skyward\n  VERSION = "0.2.0" #: String\nend\n), Release.bump(source, "0.2.0")
    end
  end

  describe ".shared" do
    it "returns the version every source agrees on" do
      assert_equal "0.1.0", Release.shared([source, source])
    end

    it "returns nil when the sources disagree" do
      assert_nil Release.shared([source, Release.bump(source, "0.2.0")])
    end
  end
end
