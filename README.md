# EnvSettings

This gem provides simple validation and parsing of `ENV`-based application
settings for Ruby. Using `ENV` directly in application code is simple and easy,
but it has unexpected pitfalls.

## Pitfalls of ENV

*Late failure*:

```ruby
Mailer.send_email(..., reply_to: ENV['EMAIL_REPLY_TO'])
```

This value could be an empty string or nil. Does that cause an error? Who knows?
Will you get paged 1 minute, 1 hour, 1 day, 1 week after deploying when it turns
out someone forgot to set the variable? Who knows?

```ruby
Mailer.send_email(..., reply_to: ENV.fetch('EMAIL_REPLY_TO'))
```

Well, at least you'll probably get paged in the 1 minute/hour range. Setting up
a codebase with a lot of this is annoying, though, because it starts to feel
like a game of whack-a-mole -- set one variable and then poke around until the
app crashes again, find out what the value is supposed to be, and repeat.

*Inconsistencies*:

```ruby
default_bcc = ENV.fetch('EMAIL_DEFAULT_BCC').split(/,/)
Mailer.send_email(..., default_bcc: default_bcc)
# somewhere else...
alert_emails = ENV.fetch('ALERT_EMAILS').split(/\s*,\s*)
Mailer.send_email(..., to: alert_emails)
```

There's no standard way to represent a list in an environment variable --
certainly not one that anyone pays attention to. EnvSettings has a reasonable
default (`/\s*,\s*/`) that you can use everywhere.

```ruby
feature_enabled = ENV['FEATURE_FOO'] == "on"
# somewhere else...
feature_enabled = ENV['FEATURE_BAR'].present?
# somewhere else...
feature_enabled = !!ENV['FEATURE_BAZ']
```

No standard way to represent a boolean, either. EnvSettings provides a
reasonable default (any non-blank string -> `true`, blank string or not set ->
`false`).

[12f]: https://12factor.net/config

## Goals and Non-Goals

*Goal: drop-in replacement for ENV*. EnvSettings produces a hash-like object
similar to `ENV`. It uses the environment variable name as the key. It isn't
much prettier than reading directly from `ENV`, but it's safer, and the
environment variable names are greppable.

*Non-goal: elegant per-component configuration*. I think this is a much better
way of writing code than reading from `ENV` everywhere. If you do this, you can
still use EnvSettings as glue to get config values from `ENV` into your neat
config system.

*Non-goal: values more structured than a list*. If for some reason you need to
stuff a hash or JSON or something into an environment variable, you can use the
`custom` method to define whatever parsing logic you want.

## Usage

Drop-in for ENV:

```ruby
ENV_SETTINGS = EnvSettings.new do |e|
  e.string "SETTING_NAME"
  e.string "OTHER_SETTING_NAME", default: "good"
end.extract(ENV)

# Replace ENV with ENV_SETTINGS in your code. If an unknown key is used, an
# exception will be raised.
```

Full example:

```ruby
fake_env = {

}
# FIXME: I actually think 'required' is redundant with 'default' now.
settings = EnvSettings.new do |e|
  e.string "FOO_NAME"
  e.string "FOO_EMAIL"
  # Strings are required by default...
  e.string "FOO_DESCRIPTION", required: false
  # ... unless a default value is provided.
  e.string "FOO_TYPE", default: "frob"
  e.boolean "FOO_ENABLED"
  # Booleans have `default: false` by default.
  e.boolean "FOO_SUPER_MODE", default: true
  e.list "FOO_IDEAS"
  e.list "FOO_ZONES", default: %w[left right up down]
  e.custom "FOO_POWER_LEVELS" do |v|
    v.nil? ? [] : v.split(":").map(&:to_i).sort
  end
end.extract(fake_env)
```

