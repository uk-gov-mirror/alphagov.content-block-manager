# Service for handling form preview requests to gov.uk domains.
# Submits form data and extracts the redirect location from the response.
#
# @example Basic usage
#   service = PreviewFormHandlerService.new(
#     url: "https://example.gov.uk/form",
#     form_body: { field: "value" }
#   )
#   redirect_path = service.response_location_path
#
class PreviewFormHandlerService
  # @return [URI] The parsed URI of the target URL
  attr_reader :uri

  # @return [Hash] The form data to be submitted
  attr_reader :form_body

  # @return [String] The HTTP method to use for the request
  attr_reader :method

  # Raised when the HTTP response is not as expected
  class UnexpectedResponseError < StandardError; end

  # Raised when the URL is not a gov.uk domain
  class UnexpectedUrlError < StandardError; end

  # Initializes a new PreviewFormHandlerService instance.
  #
  # @param url [String] The target URL to submit the form to
  # @param form_body [Hash] The form data to be submitted
  # @param method [String] The HTTP method to use for the request
  # @raise [UnexpectedUrlError] if the URL is not a gov.uk domain
  #
  def initialize(url:, form_body:, method:)
    @uri = URI.parse(url)
    @form_body = form_body
    @method = method
    raise UnexpectedUrlError unless uri.host.ends_with?("gov.uk")
  end

  # Submits the form and extracts the redirect location path.
  #
  # @return [String] The path component of the redirect location
  # @raise [UnexpectedResponseError] if the response is not a 302 redirect
  #
  def response_location_path
    unless response.code == "302"
      raise UnexpectedResponseError
    end

    location = URI.parse(response[:location])
    location.request_uri
  end

private

  def response
    @response ||= begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      request = request_class.new(request_uri)
      request.set_form_data(form_body) unless method == "get"
      http.request(request)
    end
  end

  def request_class
    method == "get" ? Net::HTTP::Get : Net::HTTP::Post
  end

  def request_uri
    if method == "get" && form_body.any?
      query = URI.encode_www_form(form_body)
      existing_query = uri.query
      combined_query = [existing_query, query].compact.join("&")
      "#{uri.path}?#{combined_query}"
    else
      uri.request_uri
    end
  end
end
