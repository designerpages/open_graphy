module OpenGraphy
  module Uri
    class Fetcher
      def initialize(uri_str, limit = 10)
        @uri_str, @limit = uri_str, limit
      end

      def fetch
        check_redirect_limit

        http_response = response
        case http_response
        when Net::HTTPSuccess then
          http_response
        when Net::HTTPRedirection then
          follow_redirection(http_response)
        else
          http_response.value
        end
      end

      private

      def follow_redirection(http_response)
        @uri_str = http_response['location']
        @limit -= 1
        self.fetch
      end

      def check_redirect_limit
        raise Uri::RedirectLoopError, 'too many HTTP redirects' if @limit == 0
      end

      def uri
        uri = URI(@uri_str)
        raise BadUriError, 'the url is incomplete' if uri.host == nil

        uri
      end

      def request
        request_object = Net::HTTP::Get.new(uri.request_uri, headers)
        # set the read timeout to 1ms
        # i.e. if we can't read the response or a chunk within 1ms this will cause a
        # Net::ReadTimeout error when the request is made
        request_object.read_timeout = 5.0
        request_object
      end

      def response
        http.request(request)
      end

      def http
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = ssl?
        end
      end

      def ssl?
        uri.scheme == 'https'
      end

      def headers
        {
          'User-Agent' => OpenGraphy.configuration.user_agent,
        }
      end

    end
  end
end
