# frozen_string_literal: true

D = Steep::Diagnostic

# Each gem's directory, and the Skyward gems it depends on.
GEMS = {
  core: { dir: "skyward-core", depends_on: [] },
  api: { dir: "skyward-api", depends_on: %i[core] },
  orm: { dir: "skyward-orm", depends_on: %i[core] },
  skyward: { dir: "skyward", depends_on: %i[core api orm] }
}.freeze

# Steep shares every target's signature files with every other target unless
# the target is `unreferenced!`. Every target is, and loads only its own
# signatures and its dependencies', so reaching into a Skyward gem it doesn't
# depend on is a type error.
GEMS.each do |name, gem|
  target name do
    unreferenced!

    [name, *gem.fetch(:depends_on)].each { |part| signature "#{GEMS.fetch(part).fetch(:dir)}/sig" }

    check "#{gem.fetch(:dir)}/lib"

    collection_config "rbs_collection.yaml"

    configure_code_diagnostics(D::Ruby.all_error)
  end
end
