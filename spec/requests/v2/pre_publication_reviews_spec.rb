RSpec.describe "V2::PrePublicationReviews", type: :request do
  let(:organisation) { build(:organisation, id: SecureRandom.uuid) }
  let(:document) { create(:v2_document, block_type: "time_period") }
  let(:edition) { create(:v2_time_period_edition, document: document, state: "draft", lead_organisation_id: organisation.id) }
  let!(:date_range) { create(:v2_time_period_date_range, edition: edition) }

  before do
    logout
    login_as(create(:user))
    allow(Organisation).to receive(:all).and_return([organisation])
  end

  let(:request_url) { "/v2/documents/#{document.id}/editions/#{edition.id}/pre-publication-reviews/new" }

  describe "GET /v2/documents/:document_id/editions/:edition_id/pre-publication-reviews/new" do
    context "when the edition exists and is valid" do
      before { get request_url }

      it "renders the review page" do
        expect(response).to have_http_status(:ok)
        expect(response).to render_template("v2/pre_publication_reviews/new")
      end

      it "renders the correct page title from the helper method" do
        expect(response.body).to include("Review time period")
      end
    end

    context "when the edition does not exist" do
      let(:request_url) { "/v2/documents/#{document.id}/invalid_id/pre-publication-reviews/new" }

      it "responds with a 404 Not Found" do
        get request_url
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "POST /v2/documents/:document_id/editions/:edition_id/pre-publication-reviews" do
    context "when the confirmation checkbox is checked" do
      let(:valid_params) { { edition: { has_checked_content: "1" } } }
      let(:workflow_service_mock) { instance_double(V2::WorkflowCompletionService) }

      before do
        allow(V2::WorkflowCompletionService).to receive(:new).and_return(workflow_service_mock)
      end

      context "when publishing is successful" do
        before do
          allow(workflow_service_mock).to receive(:call).and_return({
            path: "/completion-path",
            flash: { foo: "bar" },
          })
        end

        it "redirects to the completion path with a flash message" do
          post v2_document_edition_pre_publication_reviews_path(document_id: document.id, edition_id: edition.id, params: valid_params)

          expect(response).to redirect_to("/completion-path")
          expect(flash[:foo]).to eq("bar")
        end
      end
    end

    context "when the confirmation checkbox is NOT checked" do
      it "does not publish the edition and re-renders with a validation error" do
        post v2_document_edition_pre_publication_reviews_path(document_id: document.id, edition_id: edition.id)

        expect(edition.reload).to be_draft
        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("v2/pre_publication_reviews/new")

        expect(response.body).to include("There is a problem")
        expect(response.body).to include(
          I18n.t("v2.edition.pre_publication_review.errors.confirm"),
        )
      end
    end
  end
end
