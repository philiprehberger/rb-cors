# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Philiprehberger::Cors do
  describe 'VERSION' do
    it 'has a version number' do
      expect(Philiprehberger::Cors::VERSION).not_to be_nil
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
  end
end
