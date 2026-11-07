# frozen_string_literal: true

require "bundler"
require "date"
require "fileutils"
require "rake/testtask"
require "rubocop/rake_task"
require "tmpdir"
require_relative "tooling/lib/changelog"
require_relative "tooling/lib/release"

# In dependency order, which is the order they're built, installed and
# published in.
GEMS = %w[skyward-core skyward-api skyward-orm skyward].freeze

PKG = "pkg"

# Rake::TestTask reads TEST as a single glob, so bin/test's comma-separated
# list is taken out of ENV and split by the directory each file is in.
REQUESTED_TESTS = ENV.delete("TEST")&.split(",")

def requested_in(dir)
  return unless REQUESTED_TESTS

  prefix = File.expand_path(dir) + File::SEPARATOR
  REQUESTED_TESTS.map { |file| File.expand_path(file) }
                 .select { |path| path.start_with?(prefix) }
                 .map { |path| path.delete_prefix(prefix) }
end

def ruby_sources(gem) = Dir.glob("lib/**/*.rb", base: gem)

def write_signatures(gem, output)
  sources = ruby_sources(gem)
  # Starting empty drops a deleted file's signatures.
  FileUtils.rm_rf(File.expand_path(output, gem))
  FileUtils.mkdir_p(File.expand_path(output, gem))
  return if sources.empty?

  sh "rbs-inline", "--opt-out", "--output=#{output}", *sources, chdir: gem, verbose: false
end

# Each gem's tests run in that gem's own bundle, which holds only the gem and
# the Skyward gems it depends on, so a test that reaches for another fails.
gem_test_tasks = GEMS.filter_map do |gem|
  files = requested_in(gem)
  next if files == []

  desc "Run #{gem}'s tests in its own bundle"
  task "test:#{gem}" do
    env = { "TEST" => files&.join(",") }.compact
    Bundler.with_unbundled_env { sh env, "bundle", "exec", "rake", "test", chdir: gem }
  end
  "test:#{gem}"
end

tooling_tests = requested_in("tooling") || Dir.glob("test/**/*_test.rb", base: "tooling")
unless tooling_tests.empty?
  Rake::TestTask.new("test:tooling") do |t|
    t.libs = %w[tooling/lib tooling/test]
    t.test_files = tooling_tests.map { |file| File.expand_path(file, "tooling") }
    t.warning = false
  end
end

desc "Run every gem's tests, each in its own bundle, and the tooling's"
task test: [*gem_test_tasks, *("test:tooling" unless tooling_tests.empty?)]

RuboCop::RakeTask.new do |t|
  # RuboCop also applies AllCops/Exclude from every .rubocop.yml above the
  # project, so a checkout inside another one (a worktree under .claude/)
  # would otherwise inspect nothing and pass.
  t.options = ["--ignore-parent-exclusion", *ENV.fetch("RUBOCOP_OPTS", "").split]
end

desc "Run RuboCop"
task lint: :rubocop

namespace :rbs do
  desc "Fail if rbs_collection.lock.yaml is out of date with rbs_collection.yaml or Gemfile.lock"
  task :collection_check do
    before = File.read("rbs_collection.lock.yaml")
    sh "rbs collection update", verbose: false
    after = File.read("rbs_collection.lock.yaml")
    next if before == after

    File.write("rbs_collection.lock.yaml", before)
    abort "rbs_collection.lock.yaml is out of date; run `bin/setup` and commit the result"
  end

  desc "Install the gem signatures the collection locks"
  task :collection_install do
    sh "rbs collection install"
  end

  desc "Generate RBS signatures from inline annotations in every gem"
  task :generate do
    GEMS.each { |gem| write_signatures(gem, "sig/generated") }
  end

  desc "Fail if any gem's rbs-inline output is out of date with its Ruby"
  task :check do
    GEMS.each do |gem|
      Dir.mktmpdir("rbs-check") do |dir|
        write_signatures(gem, dir)
        FileUtils.mkdir_p("#{gem}/sig/generated")
        sh "diff -ruN #{gem}/sig/generated #{dir}" do |ok, _|
          abort "#{gem}/sig/generated is out of date; run bin/rbs and commit the result" unless ok
        end
      end
    end
  end

  desc "Watch every gem's Ruby and regenerate RBS files on change"
  task :watch do
    require "guard"
    require "guard/commander"

    Guard.start(no_interactions: true)
  end
end

namespace :steep do
  desc "Type-check every gem with Steep"
  task :check do
    # --no-daemon: Steep 2.1 otherwise routes the check through whatever
    # language server holds the project socket, including orphaned ones,
    # which can hang or report stale results.
    sh "steep check --no-daemon #{ENV.fetch("STEEP_OPTS", "")}".strip
  end
end

desc "Check the RBS signatures and collection are current, then run Steep"
task typecheck: %w[rbs:check rbs:collection_check steep:check]

namespace :package do
  desc "Build every gem into #{PKG}/"
  task :build do
    FileUtils.rm_rf(PKG)
    FileUtils.mkdir_p(PKG)
    GEMS.each do |gem|
      sh "gem", "build", "--quiet", "#{gem}.gemspec", chdir: gem
      FileUtils.mv(Dir["#{gem}/#{gem}-[0-9]*.gem"], PKG)
    end
  end

  desc "Install the built gems into an empty GEM_HOME and load them, as a user would"
  task check: :build do
    Dir.mktmpdir("skyward-gems") do |home|
      env = { "GEM_HOME" => home, "GEM_PATH" => home }
      Bundler.with_unbundled_env do
        GEMS.each { |gem| sh env, "gem", "install", "--no-document", *Dir["#{PKG}/#{gem}-[0-9]*.gem"] }
        # Eager loading every loader fails on a file the gemspec left out.
        sh env, Gem.ruby, "-e", <<~RUBY
          require "skyward"
          Zeitwerk::Loader.eager_load_all
          puts "Installed and loaded skyward \#{Skyward::VERSION} from #{PKG}/"
        RUBY
      end
    end
  end
end

namespace :release do
  desc "Set every gem to VERSION, add its changelog section and update the lockfiles"
  task :prepare, [:version] do |_task, args|
    version = args[:version].to_s
    abort "Usage: bin/release VERSION, where VERSION looks like 1.2.3 or 1.2.3.rc1" unless Release.valid?(version)

    Release::VERSION_FILES.each { |file| File.write(file, Release.bump(File.read(file), version)) }

    last_tag = `git describe --tags --abbrev=0 2>/dev/null`.strip
    subjects = `git log --format=%s #{last_tag.empty? ? "HEAD" : "#{last_tag}..HEAD"}`.lines(chomp: true)
    section = Changelog.section(version, Date.today, subjects)
    File.write("CHANGELOG.md", Changelog.prepend(File.read("CHANGELOG.md"), section))

    Bundler.with_unbundled_env { [".", *GEMS].each { |dir| sh "bundle", "lock", chdir: dir } }

    puts <<~NEXT

      Every gem is at #{version}. Review CHANGELOG.md, then open a PR titled
      `chore: release #{version}`. Once it's merged, tag the merge commit and push
      the tag, which publishes the gems:

        git tag v#{version} <merge commit> && git push origin v#{version}
    NEXT
  end

  desc "Fail unless every gem's version matches the tag being released (vX.Y.Z)"
  task :verify, [:tag] do |_task, args|
    tag = args[:tag] || ENV.fetch("GITHUB_REF_NAME")
    shared = Release.shared(Release::VERSION_FILES.map { |file| File.read(file) })
    abort "The gems' versions disagree; run bin/release" unless shared
    abort "#{tag} doesn't match the gems' version, #{shared}" unless tag == "v#{shared}"
  end
end

desc "Run everything CI runs"
task ci: %w[lint typecheck test package:check]

task default: :ci
