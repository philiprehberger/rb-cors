# frozen_string_literal: true

module Philiprehberger
  module Cors
    # Rack middleware for handling CORS requests.
    #
    # @example
    #   use Philiprehberger::Cors::Middleware,
    #     origins: ['https://example.com'],
    #     methods: %w[GET POST PUT DELETE],
    #     headers: %w[Content-Type Authorization],
    #     credentials: true,
    #     max_age: 86_400
    class Middleware
      DEFAULT_METHODS = %w[GET POST PUT PATCH DELETE HEAD OPTIONS].freeze
      DEFAULT_HEADERS = %w[Content-Type Accept Authorization].freeze
      DEFAULT_MAX_AGE = 86_400

      # Create a new CORS middleware instance.
      #
      # @param app [#call] the Rack application
      # @param origins [Array<String>, String] allowed origins ('*' for all)
      # @param methods [Array<String>] allowed HTTP methods
      # @param headers [Array<String>] allowed request headers
      # @param credentials [Boolean] whether to allow credentials
      # @param max_age [Integer] preflight cache duration in seconds
      def initialize(app, origins: '*', methods: DEFAULT_METHODS, headers: DEFAULT_HEADERS,
                     credentials: false, max_age: DEFAULT_MAX_AGE)
        @app = app
        @origins = Array(origins)
        @methods = Array(methods).map(&:upcase)
        @headers = Array(headers)
        @credentials = credentials
        @max_age = max_age
      end

      # Process a Rack request.
      #
      # @param env [Hash] the Rack environment
      # @return [Array] Rack response triplet [status, headers, body]
      def call(env)
        origin = env['HTTP_ORIGIN']
        return @app.call(env) unless origin

        return @app.call(env) unless origin_allowed?(origin)

        if preflight?(env)
          preflight_response(origin)
        else
          status, headers, body = @app.call(env)
          headers = add_cors_headers(headers, origin)
          [status, headers, body]
        end
      end

      private

      def preflight?(env)
        env['REQUEST_METHOD'] == 'OPTIONS' && env.key?('HTTP_ACCESS_CONTROL_REQUEST_METHOD')
      end

      def origin_allowed?(origin)
        @origins.include?('*') || @origins.include?(origin)
      end

      def preflight_response(origin)
        headers = {
          'Access-Control-Allow-Origin' => allowed_origin(origin),
          'Access-Control-Allow-Methods' => @methods.join(', '),
          'Access-Control-Allow-Headers' => @headers.join(', '),
          'Access-Control-Max-Age' => @max_age.to_s,
          'Content-Type' => 'text/plain'
        }
        headers['Access-Control-Allow-Credentials'] = 'true' if @credentials
        headers['Vary'] = 'Origin' unless @origins.include?('*')
        [204, headers, []]
      end

      def add_cors_headers(headers, origin)
        headers['Access-Control-Allow-Origin'] = allowed_origin(origin)
        headers['Access-Control-Allow-Credentials'] = 'true' if @credentials
        headers['Vary'] = 'Origin' unless @origins.include?('*')
        headers
      end

      def allowed_origin(origin)
        if @origins.include?('*') && !@credentials
          '*'
        else
          origin
        end
      end
    end
  end
end
