# philiprehberger-cors

[![Tests](https://github.com/philiprehberger/rb-cors/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-cors/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-cors.svg)](https://rubygems.org/gems/philiprehberger-cors)
[![Last updated](https://img.shields.io/github/last-commit/philiprehberger/rb-cors)](https://github.com/philiprehberger/rb-cors/commits/main)

CORS middleware with origin validation and preflight handling

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-cors"
```

Or install directly:

```bash
gem install philiprehberger-cors
```

## Usage

```ruby
require "philiprehberger/cors"

use Philiprehberger::Cors::Middleware,
  origins: ['https://example.com'],
  methods: %w[GET POST PUT DELETE],
  headers: %w[Content-Type Authorization],
  credentials: true,
  max_age: 86_400
```

### Wildcard Origins

```ruby
use Philiprehberger::Cors::Middleware, origins: '*'
```

### Multiple Origins

```ruby
use Philiprehberger::Cors::Middleware,
  origins: ['https://app.example.com', 'https://admin.example.com']
```

### Regex Origins

```ruby
use Philiprehberger::Cors::Middleware,
  origins: [/\.example\.com$/, "http://localhost:3000"]
```

### Expose Headers

```ruby
use Philiprehberger::Cors::Middleware,
  origins: "*",
  expose_headers: ["X-Request-Id", "X-Total-Count"]
```

### Reflect Request Headers

Echo whatever the client sent in `Access-Control-Request-Headers`:

```ruby
use Philiprehberger::Cors::Middleware,
  origins: ['https://app.example.com'],
  headers: :reflect
```

### Private Network Access

Opt into Chrome's Private Network Access preflight extension:

```ruby
use Philiprehberger::Cors::Middleware,
  origins: ['https://app.example.com'],
  allow_private_network: true
```

### With Credentials

```ruby
use Philiprehberger::Cors::Middleware,
  origins: ['https://app.example.com'],
  credentials: true
```

### Inspecting Configured Origins

Expose the configured origin list for logging or diagnostics:

```ruby
middleware = Philiprehberger::Cors::Middleware.new(app, origins: ['https://app.example.com'])
middleware.allowed_origins # => ["https://app.example.com"]

wildcard = Philiprehberger::Cors::Middleware.new(app, origins: '*')
wildcard.allowed_origins   # => :any
```

### Checking a Specific Origin

Unit-test your CORS policy without building a Rack env:

```ruby
middleware = Philiprehberger::Cors::Middleware.new(app, origins: [/\.example\.com$/])
middleware.allows_origin?('https://api.example.com') # => true
middleware.allows_origin?('https://evil.test')       # => false
```

## API

### `Cors::Middleware`

| Method | Description |
|--------|-------------|
| `.new(app, origins:, methods:, headers:, credentials:, max_age:, expose_headers:, allow_private_network:)` | Create CORS middleware |
| `#allowed_origins` | Return the configured origins (Array) or `:any` when wildcard |
| `#allows_origin?(origin)` | Return `true` if the given origin is permitted by the configured policy |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `origins` | `'*'` | Allowed origins (string or array) |
| `methods` | `GET POST PUT PATCH DELETE HEAD OPTIONS` | Allowed HTTP methods |
| `headers` | `Content-Type Accept Authorization` | Allowed request headers, or `:reflect` to echo `Access-Control-Request-Headers` |
| `credentials` | `false` | Allow credentials |
| `max_age` | `86400` | Preflight cache duration in seconds |
| `expose_headers` | `[]` | Array of header names clients can read |
| `allow_private_network` | `false` | Enable Chrome's Private Network Access preflight header |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## Support

If you find this project useful:

⭐ [Star the repo](https://github.com/philiprehberger/rb-cors)

🐛 [Report issues](https://github.com/philiprehberger/rb-cors/issues?q=is%3Aissue+is%3Aopen+label%3Abug)

💡 [Suggest features](https://github.com/philiprehberger/rb-cors/issues?q=is%3Aissue+is%3Aopen+label%3Aenhancement)

❤️ [Sponsor development](https://github.com/sponsors/philiprehberger)

🌐 [All Open Source Projects](https://philiprehberger.com/open-source-packages)

💻 [GitHub Profile](https://github.com/philiprehberger)

🔗 [LinkedIn Profile](https://www.linkedin.com/in/philiprehberger)

## License

[MIT](LICENSE)
