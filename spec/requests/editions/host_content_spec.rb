RSpec.describe "Host content", type: :request do
  include Rails.application.routes.url_helpers

  setup do
    logout
    user = create(:user)
    login_as(user)
  end

  describe "#form_handler" do
    let(:host_content_id) { SecureRandom.uuid }
    let(:locale) { "en" }
    let(:params) do
      {
        id: 123,
        url: "https://www.gov.uk/foo",
        method: "post",
        host_content_id:,
        locale:,
      }
    end
    let(:body) { { "foo" => "bar" } }
    let(:edition) { build_stubbed(:edition) }

    before do
      allow(Edition).to receive(:find).with(params[:id].to_s).and_return(edition)
    end

    it "redirects to the response_location_path" do
      form_handler_mock = instance_double(PreviewFormHandlerService, response_location_path: "/preview/123")

      expect(PreviewFormHandlerService).to receive(:new)
                                             .with(
                                               url: params[:url],
                                               form_body: body,
                                               method: params[:method],
                                             )
                                             .and_return(form_handler_mock)

      expected_redirect_path = host_content_preview_edition_path(
        id: edition.id,
        host_content_id: params[:host_content_id],
        locale: params[:locale],
        base_path: form_handler_mock.response_location_path,
      )

      post host_content_preview_form_handler_edition_path(params), params: { body: }

      expect(response).to redirect_to(expected_redirect_path)
    end

    it "returns a bad request if the service raises an unexpected response error" do
      expect(PreviewFormHandlerService).to receive(:new)
                                       .and_raise(PreviewFormHandlerService::UnexpectedResponseError)

      post host_content_preview_form_handler_edition_path(params), params: { body: }

      expect(response.code).to eq("400")
    end

    it "returns a bad request if the service raises an unexpected url error" do
      expect(PreviewFormHandlerService).to receive(:new)
                                       .and_raise(PreviewFormHandlerService::UnexpectedResponseError)

      post host_content_preview_form_handler_edition_path(params), params: { body: }

      expect(response.code).to eq("400")
    end
  end
end
