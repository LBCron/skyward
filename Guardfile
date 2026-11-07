# frozen_string_literal: true

guard :shell do
  watch(%r{^(skyward-core|skyward-api|skyward-orm|skyward)/lib/.*\.rb$}) do
    system("bundle exec rake rbs:generate")
  end
end
