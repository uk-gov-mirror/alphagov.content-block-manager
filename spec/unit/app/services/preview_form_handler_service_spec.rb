RSpec.describe PreviewFormHandlerService do
  let(:valid_url) { "https://example.gov.uk/form" }
  let(:form_body) { { field: "value", another_field: "data" } }
  let(:method) { "post" }

  describe "#initialize" do
    context "with a valid gov.uk URL" do
      it "successfully creates an instance" do
        service = described_class.new(url: valid_url, form_body: form_body, method:)
        expect(service).to be_a(PreviewFormHandlerService)
      end
    end

    context "with a subdomain of gov.uk" do
      it "accepts the URL" do
        url = "https://subdomain.example.gov.uk/path"
        service = described_class.new(url: url, form_body: form_body, method:)
        expect(service).to be_a(PreviewFormHandlerService)
      end
    end

    context "with an invalid URL" do
      it "raises UnexpectedUrlError for non-gov.uk domains" do
        invalid_url = "https://example.com/form"
        expect {
          described_class.new(url: invalid_url, form_body: form_body, method:)
        }.to raise_error(PreviewFormHandlerService::UnexpectedUrlError)
      end

      it "raises UnexpectedUrlError for URLs that contain but don't end with gov.uk" do
        invalid_url = "https://gov.uk.fake.com/form"
        expect {
          described_class.new(url: invalid_url, form_body: form_body, method:)
        }.to raise_error(PreviewFormHandlerService::UnexpectedUrlError)
      end
    end
  end

  describe "#response_location_path" do
    let(:service) { described_class.new(url: valid_url, form_body: form_body, method:) }
    let(:mock_http) { instance_double(Net::HTTP) }
    let(:mock_request) { instance_double(Net::HTTP::Get) }
    let(:mock_response) { instance_double(Net::HTTPResponse) }

    let(:redirect_location) { "https://example.gov.uk/preview/123" }

    before do
      allow(Net::HTTP).to receive(:new).with("example.gov.uk", 443).and_return(mock_http)
      allow(Net::HTTP::Post).to receive(:new).and_return(mock_request)
      allow(mock_request).to receive(:set_form_data).with(form_body)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:request).with(mock_request).and_return(mock_response)
      allow(mock_response).to receive(:code).and_return(response_code)
      allow(mock_response).to receive(:[]).with(:location).and_return(redirect_location)
    end

    context "when response is a 302 redirect" do
      let(:response_code) { "302" }

      it "returns the path of the redirect location" do
        expect(service.response_location_path).to eq("/preview/123")
      end

      it "sets use_ssl to true" do
        service.response_location_path
        expect(mock_http).to have_received(:use_ssl=).with(true)
      end

      context "when the url is a http url" do
        let(:valid_url) { "http://example.dev.gov.uk/form" }

        before do
          allow(Net::HTTP).to receive(:new).with("example.dev.gov.uk", 80).and_return(mock_http)
        end

        it "sets use_ssl to false" do
          service.response_location_path
          expect(mock_http).to have_received(:use_ssl=).with(false)
        end
      end

      context "when the method is get" do
        let(:method) { "get" }

        it "sets the request method to get and includes the full path" do
          expect(Net::HTTP::Get).to receive(:new)
                                .with("/form?field=value&another_field=data")
                                .and_return(mock_request)
          expect(mock_request).not_to receive(:set_form_data)

          service.response_location_path
        end

        context "when the url contains existing query parameters" do
          let(:valid_url) { "https://example.gov.uk/form?foo=bar" }

          it "appends the form body to the existing params" do
            expect(Net::HTTP::Get).to receive(:new)
                                        .with("/form?foo=bar&field=value&another_field=data")
                                        .and_return(mock_request)
            expect(mock_request).not_to receive(:set_form_data)

            service.response_location_path
          end
        end
      end

      context "when the method is post" do
        let(:method) { "post" }

        it "sets the request method to post and sets the body as form data" do
          expect(Net::HTTP::Post).to receive(:new).and_return(mock_request)
          expect(mock_request).to receive(:set_form_data).with(form_body)

          service.response_location_path
        end
      end
    end

    context "when response has a redirect with query parameters" do
      let(:redirect_location) { "https://example.gov.uk/preview/123?param=value" }
      let(:response_code) { "302" }

      it "returns only the path without query parameters" do
        expect(service.response_location_path).to eq("/preview/123?param=value")
      end
    end

    context "when response is not a 302" do
      let(:response_code) { "200" }

      it "raises UnexpectedResponseError" do
        expect {
          service.response_location_path
        }.to raise_error(PreviewFormHandlerService::UnexpectedResponseError)
      end
    end

    context "when response is a 301 redirect" do
      let(:response_code) { "301" }

      it "raises UnexpectedResponseError" do
        expect {
          service.response_location_path
        }.to raise_error(PreviewFormHandlerService::UnexpectedResponseError)
      end
    end

    context "when response is a 404" do
      let(:response_code) { "404" }

      it "raises UnexpectedResponseError" do
        expect {
          service.response_location_path
        }.to raise_error(PreviewFormHandlerService::UnexpectedResponseError)
      end
    end
  end
end
