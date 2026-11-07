# Skyward

Typed Ruby web apps, where an endpoint is a method and a row is a value. This gem installs both halves of Skyward:

- [Skyward API](../skyward-api/README.md), a web framework where an endpoint is a method, typed with RBS.
- [Skyward ORM](../skyward-orm/README.md), an ORM where a class is a table and its rows are frozen values, typed with RBS.

Each works without the other. Add this gem when you want both.

## Install

```ruby
# Gemfile
gem "skyward"
```

```ruby
require "skyward" # requires skyward/api and skyward/orm
```

Skyward supports every Ruby that isn't end-of-life (3.3 and later, as of November 2026).

## Starting an app

```sh
$ skyward new todos
```

`skyward new` writes a working app: `app.rb` and `boot.rb`, a `Steepfile` with typing set up, tests, `bin/ci`, and an `AGENTS.md` that teaches an agent working in the app its conventions.

## Status

This README is the spec. Skyward 0.1 is a skeleton: `require "skyward"` loads both gems, and `skyward new` isn't built yet. It arrives once Skyward API and Skyward ORM are both built.
