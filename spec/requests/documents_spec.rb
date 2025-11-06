RSpec.describe "Documents", type: :request do
  include Rails.application.routes.url_helpers

  let(:organisation) { build(:organisation) }

  setup do
    logout
    user = create(:user)
    login_as(user)

    allow(Organisation).to receive(:all).and_return([organisation])
  end

  describe "#index" do
    let(:document) { create(:document, :contact) }

    before do
      stub_request_for_schema(document.block_type, fields: [double(:field, name: "email_address")])
    end

    it "only returns the latest edition when multiple editions exist for a document" do
      first_edition = create(
        :edition,
        :contact,
        details: { "email_address" => "first_edition@example.com" },
        document: document,
        lead_organisation_id: organisation.id,
      )
      second_edition = create(
        :edition,
        :contact,
        :latest,
        details: { "email_address" => "second_edition@example.com" },
        document: document,
        lead_organisation_id: organisation.id,
      )

      get documents_path
      follow_redirect!

      expect(page).to_not have_text(first_edition.details["email_address"])
      expect(page).to have_text(second_edition.details["email_address"])
    end

    it "only returns documents with a latest edition" do
      document.latest_edition = create(
        :edition,
        :contact,
        :latest,
        details: { "email_address" => "live_edition@example.com" },
        document: document,
        lead_organisation_id: organisation.id,
      )
      _document_without_latest_edition = create(:document, :contact, sluggable_string: "no latest edition")

      get documents_path({ lead_organisation: "" })

      expect(page).to have_text(document.latest_edition.details["email_address"])
      expect(page).to have_text("1 result")
    end

    describe "when no filter params are specified" do
      it "sets the filter to 'all organisations' by default" do
        get documents_path

        expect(response).to redirect_to(root_path({ lead_organisation: "" }))
      end
    end

    describe "when there are filter params provided" do
      it "does not change the params" do
        get documents_path({ lead_organisation: organisation.id })

        expect(response).not_to have_http_status(:redirect)
      end
    end
  end

  describe "#new" do
    let(:schemas) { build_list(:schema, 1, body: { "properties" => {} }) }

    it "lists all schemas" do
      allow(Schema).to receive(:all).and_return(schemas)

      get new_document_path

      expect(page).to have_text("Select a content block")
    end
  end

  describe "#new_document_options_redirect" do
    let(:schemas) { build_list(:schema, 1, body: { "properties" => {} }) }

    before do
      allow(Schema).to receive(:all).and_return(schemas)
    end

    it "shows an error message when block type is empty" do
      post new_document_options_redirect_documents_path

      expect(response).to redirect_to(new_document_path)

      follow_redirect!

      expect(flash[:error]).to eq(I18n.t("activerecord.errors.models.document.attributes.block_type.blank"))
    end

    it "redirects when the block type is specified" do
      block_type = schemas[0].block_type
      allow(Schema).to receive(:find_by_block_type).and_return(schemas[0])

      post new_document_options_redirect_documents_path, params: { block_type: }

      expect(response).to redirect_to(new_edition_path(block_type:))
    end
  end

  describe "#show" do
    let(:edition) { create(:edition, :contact, :latest, lead_organisation_id: organisation.id) }
    let(:document) { edition.document }

    before do
      stub_request_for_schema(document.block_type)
      stub_publishing_api_has_embedded_content_for_any_content_id(
        results: [],
        total: 0,
        order: HostContentItem::DEFAULT_ORDER,
      )
    end

    it "returns information about the document" do
      get document_path(document)

      expect(page).to have_text(document.title)
    end
  end

  describe "#content_id" do
    it "returns 404 if the document doesn't exist" do
      get content_id_path("123")
      expect(page).to have_text("Could not find Content Block with Content ID 123")
    end
  end
end
