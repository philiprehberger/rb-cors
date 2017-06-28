# philiprehberger-cors

[![Tests](https://github.com/philiprehberger/rb-cors/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-cors/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-cors.svg)](https://rubygems.org/gems/philiprehberger-cors)
[![License](https://img.shields.io/github/license/philiprehberger/rb-cors)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub%20Sponsors-ec6cb9)](https://github.com/sponsors/philiprehberger)

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

### With Credentials

```ruby
use Philiprehberger::Cors::Middleware,
  origins: ['https://app.example.com'],
  credentials: true
```

## API

### `Cors::Middleware`

| Method | Description |
|--------|-------------|
| `.new(app, origins:, methods:, headers:, credentials:, max_age:)` | Create CORS middleware |

### Options

| Option | Default | Description |
|--------|---------|-------------|
| `origins` | `'*'` | Allowed origins (string or array) |
| `methods` | `GET POST PUT PATCH DELETE HEAD OPTIONS` | Allowed HTTP methods |
| `headers` | `Content-Type Accept Authorization` | Allowed request headers |
| `credentials` | `false` | Allow credentials |
| `max_age` | `86400` | Preflight cache duration in seconds |

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
