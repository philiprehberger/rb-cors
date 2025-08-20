# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Cors do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::Cors::VERSION).not_to be_nil
    end
  end

  describe 'Error' do
    it 'is a subclass of StandardError' do
      expect(Philiprehberger::Cors::Error).to be < StandardError
    end
  end
end

RSpec.describe Philiprehberger::Cors::Middleware do
  let(:inner_app) { ->(_env) { [200, { 'Content-Type' => 'text/plain' }, ['OK']] } }
  let(:app) { described_class.new(inner_app, **options) }
  let(:options) { { origins: '*' } }

  def env_for(method: 'GET', origin: 'https://example.com', extras: {})
    base = {
      'REQUEST_METHOD' => method,
      'HTTP_ORIGIN' => origin
    }
    base.merge(extras)
  end

  describe 'simple CORS request' do
    it 'adds Access-Control-Allow-Origin header' do
      status, headers, _body = app.call(env_for)
      expect(status).to eq(200)
      expect(headers['Access-Control-Allow-Origin']).to eq('*')
    end

    it 'passes through requests without Origin header' do
      env = { 'REQUEST_METHOD' => 'GET' }
      status, headers, _body = app.call(env)
      expect(status).to eq(200)
      expect(headers).not_to have_key('Access-Control-Allow-Origin')
    end

    it 'preserves the original response body' do
      _status, _headers, body = app.call(env_for)
      expect(body).to eq(['OK'])
    end

    it 'preserves original response headers' do
      _status, headers, _body = app.call(env_for)
      expect(headers['Content-Type']).to eq('text/plain')
    end
  end

  describe 'preflight request' do
    it 'responds to OPTIONS with CORS headers' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      status, headers, _body = app.call(env)
      expect(status).to eq(204)
      expect(headers['Access-Control-Allow-Origin']).to eq('*')
      expect(headers['Access-Control-Allow-Methods']).to include('POST')
      expect(headers['Access-Control-Max-Age']).to eq('86400')
    end

    it 'includes allowed headers' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Headers']).to include('Content-Type')
    end

    it 'returns empty body for preflight' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, _headers, body = app.call(env)
      expect(body).to eq([])
    end

    it 'returns Content-Type text/plain for preflight' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Content-Type']).to eq('text/plain')
    end

    it 'treats OPTIONS without Access-Control-Request-Method as normal request' do
      env = env_for(method: 'OPTIONS')
      status, _headers, body = app.call(env)
      expect(status).to eq(200)
      expect(body).to eq(['OK'])
    end
  end

  describe 'origin validation' do
    let(:options) { { origins: ['https://allowed.com'] } }

    it 'allows matching origin' do
      status, headers, _body = app.call(env_for(origin: 'https://allowed.com'))
      expect(status).to eq(200)
      expect(headers['Access-Control-Allow-Origin']).to eq('https://allowed.com')
    end

    it 'rejects non-matching origin' do
      status, headers, _body = app.call(env_for(origin: 'https://evil.com'))
      expect(status).to eq(200)
      expect(headers).not_to have_key('Access-Control-Allow-Origin')
    end

    it 'adds Vary header for specific origins' do
      _status, headers, _body = app.call(env_for(origin: 'https://allowed.com'))
      expect(headers['Vary']).to eq('Origin')
    end

    it 'does not add Vary header for wildcard origin' do
      wildcard_app = described_class.new(inner_app, origins: '*')
      _status, headers, _body = wildcard_app.call(env_for)
      expect(headers).not_to have_key('Vary')
    end

    it 'rejects disallowed origin on preflight' do
      env = env_for(method: 'OPTIONS', origin: 'https://evil.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      status, headers, _body = app.call(env)
      expect(status).to eq(200)
      expect(headers).not_to have_key('Access-Control-Allow-Origin')
    end

    context 'with multiple allowed origins' do
      let(:options) { { origins: ['https://one.com', 'https://two.com'] } }

      it 'allows first origin' do
        _status, headers, _body = app.call(env_for(origin: 'https://one.com'))
        expect(headers['Access-Control-Allow-Origin']).to eq('https://one.com')
      end

      it 'allows second origin' do
        _status, headers, _body = app.call(env_for(origin: 'https://two.com'))
        expect(headers['Access-Control-Allow-Origin']).to eq('https://two.com')
      end

      it 'rejects unlisted origin' do
        _status, headers, _body = app.call(env_for(origin: 'https://three.com'))
        expect(headers).not_to have_key('Access-Control-Allow-Origin')
      end
    end

    it 'performs exact match on origin strings' do
      _status, headers, _body = app.call(env_for(origin: 'https://allowed.com:8080'))
      expect(headers).not_to have_key('Access-Control-Allow-Origin')
    end
  end

  describe 'credentials' do
    let(:options) { { origins: ['https://app.com'], credentials: true } }

    it 'includes Access-Control-Allow-Credentials' do
      _status, headers, _body = app.call(env_for(origin: 'https://app.com'))
      expect(headers['Access-Control-Allow-Credentials']).to eq('true')
    end

    it 'echoes the origin instead of wildcard' do
      _status, headers, _body = app.call(env_for(origin: 'https://app.com'))
      expect(headers['Access-Control-Allow-Origin']).to eq('https://app.com')
    end

    it 'includes credentials header on preflight' do
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Credentials']).to eq('true')
    end

    it 'echoes origin on preflight with credentials and wildcard' do
      cred_app = described_class.new(inner_app, origins: '*', credentials: true)
      env = env_for(method: 'OPTIONS', origin: 'https://any.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = cred_app.call(env)
      expect(headers['Access-Control-Allow-Origin']).to eq('https://any.com')
    end

    context 'when credentials is false' do
      let(:options) { { origins: '*', credentials: false } }

      it 'does not include Access-Control-Allow-Credentials' do
        _status, headers, _body = app.call(env_for)
        expect(headers).not_to have_key('Access-Control-Allow-Credentials')
      end
    end
  end

  describe 'custom methods and headers' do
    let(:options) { { origins: '*', methods: %w[GET POST], headers: %w[X-Custom Authorization] } }

    it 'returns custom methods in preflight' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Methods']).to eq('GET, POST')
    end

    it 'returns custom headers in preflight' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Headers']).to eq('X-Custom, Authorization')
    end
  end

  describe 'max_age' do
    let(:options) { { origins: '*', max_age: 3600 } }

    it 'uses custom max_age' do
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Max-Age']).to eq('3600')
    end

    it 'uses default max_age of 86400' do
      default_app = described_class.new(inner_app, origins: '*')
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = default_app.call(env)
      expect(headers['Access-Control-Max-Age']).to eq('86400')
    end
  end

  describe 'default configuration' do
    it 'includes all default methods in preflight' do
      default_app = described_class.new(inner_app, origins: '*')
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = default_app.call(env)
      allowed = headers['Access-Control-Allow-Methods']
      %w[GET POST PUT PATCH DELETE HEAD OPTIONS].each do |m|
        expect(allowed).to include(m)
      end
    end

    it 'includes default headers in preflight' do
      default_app = described_class.new(inner_app, origins: '*')
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = default_app.call(env)
      allowed = headers['Access-Control-Allow-Headers']
      expect(allowed).to include('Content-Type')
      expect(allowed).to include('Accept')
      expect(allowed).to include('Authorization')
    end
  end

  describe 'Vary header on preflight' do
    it 'includes Vary for specific origin preflight' do
      specific_app = described_class.new(inner_app, origins: ['https://specific.com'])
      env = env_for(method: 'OPTIONS', origin: 'https://specific.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = specific_app.call(env)
      expect(headers['Vary']).to include('Origin')
      expect(headers['Vary']).to include('Access-Control-Request-Method')
    end

    it 'does not include Vary for wildcard origin preflight' do
      wildcard_app = described_class.new(inner_app, origins: '*')
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = wildcard_app.call(env)
      expect(headers).not_to have_key('Vary')
    end
  end

  describe 'regex origin matching' do
    let(:app) { described_class.new(inner_app, origins: [/\.example\.com$/]) }

    it 'allows matching regex origin' do
      _status, headers, _body = app.call(env_for(origin: 'http://sub.example.com'))
      expect(headers['Access-Control-Allow-Origin']).to eq('http://sub.example.com')
    end

    it 'rejects non-matching regex origin' do
      _status, headers, _body = app.call(env_for(origin: 'http://evil.com'))
      expect(headers['Access-Control-Allow-Origin']).to be_nil
    end

    it 'works with mixed string and regex origins' do
      mixed_app = described_class.new(inner_app, origins: ['http://exact.com', /\.example\.com$/])
      _status, headers, _body = mixed_app.call(env_for(origin: 'http://exact.com'))
      expect(headers['Access-Control-Allow-Origin']).to eq('http://exact.com')
    end

    it 'works with regex in preflight' do
      env = env_for(method: 'OPTIONS', origin: 'http://sub.example.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      status, headers, _body = app.call(env)
      expect(status).to eq(204)
      expect(headers['Access-Control-Allow-Origin']).to eq('http://sub.example.com')
    end
  end

  describe 'expose_headers' do
    let(:app) { described_class.new(inner_app, expose_headers: %w[X-Request-Id X-Total-Count]) }

    it 'includes Access-Control-Expose-Headers' do
      _status, headers, _body = app.call(env_for)
      expect(headers['Access-Control-Expose-Headers']).to eq('X-Request-Id, X-Total-Count')
    end

    it 'omits header when expose_headers is empty' do
      empty_app = described_class.new(inner_app)
      _status, headers, _body = empty_app.call(env_for)
      expect(headers['Access-Control-Expose-Headers']).to be_nil
    end

    it 'works with single header' do
      single_app = described_class.new(inner_app, expose_headers: ['X-Request-Id'])
      _status, headers, _body = single_app.call(env_for)
      expect(headers['Access-Control-Expose-Headers']).to eq('X-Request-Id')
    end
  end

  describe 'headers: :reflect' do
    let(:app) { described_class.new(inner_app, origins: ['https://app.com'], headers: :reflect) }

    it 'echoes Access-Control-Request-Headers on preflight' do
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
                      'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'X-Custom-One, X-Custom-Two'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Headers']).to eq('X-Custom-One, X-Custom-Two')
    end

    it 'returns empty string when request has no requested headers' do
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Headers']).to eq('')
    end

    it 'adds Access-Control-Request-Headers to Vary' do
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
                      'HTTP_ACCESS_CONTROL_REQUEST_HEADERS' => 'X-Foo'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Vary']).to include('Access-Control-Request-Headers')
    end
  end

  describe 'allow_private_network' do
    let(:app) do
      described_class.new(inner_app, origins: ['https://app.com'], allow_private_network: true)
    end

    it 'sets Access-Control-Allow-Private-Network when requested' do
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
                      'HTTP_ACCESS_CONTROL_REQUEST_PRIVATE_NETWORK' => 'true'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Private-Network']).to eq('true')
    end

    it 'omits header when private network not requested' do
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST'
                    })
      _status, headers, _body = app.call(env)
      expect(headers).not_to have_key('Access-Control-Allow-Private-Network')
    end

    it 'omits header when allow_private_network is false (default)' do
      default_app = described_class.new(inner_app, origins: ['https://app.com'])
      env = env_for(method: 'OPTIONS', origin: 'https://app.com', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'POST',
                      'HTTP_ACCESS_CONTROL_REQUEST_PRIVATE_NETWORK' => 'true'
                    })
      _status, headers, _body = default_app.call(env)
      expect(headers).not_to have_key('Access-Control-Allow-Private-Network')
    end
  end

  describe 'methods are uppercased' do
    it 'uppercases lowercase method names' do
      app = described_class.new(inner_app, origins: '*', methods: %w[get post])
      env = env_for(method: 'OPTIONS', extras: {
                      'HTTP_ACCESS_CONTROL_REQUEST_METHOD' => 'GET'
                    })
      _status, headers, _body = app.call(env)
      expect(headers['Access-Control-Allow-Methods']).to eq('GET, POST')
    end
  end
end
