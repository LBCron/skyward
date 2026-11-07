# frozen_string_literal: true

module RuboCop::Cop::Local
  class NoInheritance < RuboCop::Cop::Base
    MSG = "Compose, don't inherit: pass collaborators in, and describe contracts as RBS interfaces. " \
          "Only errors and the framework parents in AllowedParents may be superclasses."

    def on_class(node)
      parent = node.parent_class
      return unless parent&.const_type?

      name = parent.const_name.delete_prefix("::")
      return if name.end_with?("Error") || allowed_parents.include?(name)

      add_offense(parent)
    end

    private

    def allowed_parents = cop_config.fetch("AllowedParents", [])
  end
end
