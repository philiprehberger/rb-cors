# frozen_string_literal: true

module Philiprehberger
  module Cors
    # Rack middleware for handling CORS requests.
    #
    # Supports wildcard, exact, and regex origin matching, preflight handling,
    # credentials, exposed headers, header reflection, and Chrome's Private
    # Network Access (PNA) preflight extension.
    #
    # @example Basic usage
    #   use Philiprehberger::Cors::Middleware,
    #     origins: ['https://example.com'],
    #     methods: %w[GET POST PUT DELETE],
    #     headers: %w[Content-Type Authorization],
    #     credentials: true,
    #     max_age: 86_400
    #
    # @example Reflect request headers
    #   use Philiprehberger::Cors::Middleware,
    #     origins: ['https://app.example.com'],
    #     headers: :reflect
    #
    # @example Private Network Access
    #   use Philiprehberger::Cors::Middleware,
    #     origins: ['https://app.example.com'],
    #     allow_private_network: true
    class Middleware
      DEFAULT_METHODS = %w[GET POST PUT PATCH DELETE HEAD OPTIONS].freeze
      DEFAULT_HEADERS = %w[Content-Type Accept Authorization].freeze
      DEFAULT_MAX_AGE = 86_400

      # Create a new CORS middleware instance.
      #
      # @param app [#call] the Rack application
      # @param origins [Array<String, Regexp>, String] allowed origins ('*' for all)
      # @param methods [Array<String>] allowed HTTP methods
      # @param headers [Array<String>, Symbol] allowed request headers, or
      #   +:reflect+ to echo the +Access-Control-Request-Headers+ header back
      #   to the client on preflight requests
      # @param credentials [Boolean] whether to allow credentials
      # @param max_age [Integer] preflight cache duration in seconds
      # @param expose_headers [Array<String>] headers the client is allowed to read
      # @param allow_private_network [Boolean] enable Chrome's Private Network
      #   Access preflight response header
      #   (+Access-Control-Allow-Private-Network+)
      def initialize(app, origins: '*', methods: DEFAULT_METHODS, headers: DEFAULT_HEADERS,
                     credentials: false, max_age: DEFAULT_MAX_AGE, expose_headers: [],
                     allow_private_network: false)
        @app = app
        @origins = origins
        @methods = Array(methods).map { |m| m.to_s.upcase }
        @headers = headers
        @reflect_headers = headers == :reflect
        @allowed_headers = @reflect_headers ? [] : Array(headers)
        @credentials = credentials
        @max_age = max_age
        @expose_headers = Array(expose_headers)
        @allow_private_network = allow_private_network
      end

      # Return the configured origins for introspection or logging.
      #
      # Wildcard configurations (+'*'+) are surfaced as the symbol +:any+.
      # Any other configuration is normalized to an Array of the original
      # entries (strings and/or Regexp objects).
      #
      # @return [Array<String, Regexp>, Symbol] configured origins, or +:any+
      def allowed_origins
        return :any if @origins == '*'

        Array(@origins)
      end

      # Process a Rack request.
      #
      # @param env [Hash] the Rack environment
      # @return [Array(Integer, Hash, #each)] Rack response triplet
      def call(env)
        origin = env['HTTP_ORIGIN']
        return @app.call(env) unless origin
        return @app.call(env) unless origin_allowed?(origin)

        if preflight?(env)
          preflight_response(origin, env)
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
        return true if @origins == '*'

        Array(@origins).any? do |allowed|
          case allowed
          when Regexp then allowed.match?(origin)
          else allowed == origin
          end
        end
      end

      def preflight_response(origin, env)
        headers = {
          'Access-Control-Allow-Origin' => allowed_origin(origin),
          'Access-Control-Allow-Methods' => @methods.join(', '),
          'Access-Control-Allow-Headers' => allow_headers_value(env),
          'Access-Control-Max-Age' => @max_age.to_s,
          'Content-Type' => 'text/plain'
        }
        headers['Access-Control-Allow-Credentials'] = 'true' if @credentials
        headers['Vary'] = preflight_vary unless @origins == '*'
        if @allow_private_network && env['HTTP_ACCESS_CONTROL_REQUEST_PRIVATE_NETWORK'] == 'true'
          headers['Access-Control-Allow-Private-Network'] = 'true'
        end
        [204, headers, []]
      end

      def add_cors_headers(headers, origin)
        headers['Access-Control-Allow-Origin'] = allowed_origin(origin)
        headers['Access-Control-Allow-Credentials'] = 'true' if @credentials
        headers['Vary'] = 'Origin' unless @origins == '*'
        headers['Access-Control-Expose-Headers'] = @expose_headers.join(', ') unless @expose_headers.empty?
        headers
      end

      def allowed_origin(origin)
        if @origins == '*' && !@credentials
          '*'
        else
          origin
        end
      end

      def allow_headers_value(env)
        if @reflect_headers
          env['HTTP_ACCESS_CONTROL_REQUEST_HEADERS'].to_s
        else
          @allowed_headers.join(', ')
        end
      end

      def preflight_vary
        parts = %w[Origin Access-Control-Request-Method]
        parts << 'Access-Control-Request-Headers' if @reflect_headers
        parts.join(', ')
      end
    end
  end
end
