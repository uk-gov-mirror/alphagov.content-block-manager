RSpec.describe "V2 time period editions", type: :request do
  before do
    logout
    login_as(create(:user))
  end

  describe "GET /v2/time_period_editions/new" do
    describe "when rendering the new template" do
      before do
        allow(Organisation).to receive(:all).and_return([])

        get new_v2_time_period_edition_path
      end

      it "renders the correct page successfully" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("v2/time_period_editions/new")
      end

      it "contains the correct form with the required fields" do
        expect(page).to have_css("form[action='#{v2_time_period_editions_path}']") do |form|
          expect(form).to have_field("edition[title]")
          expect(form).to have_field("edition[description]")
          expect(form).to have_field("edition[lead_organisation_id]")
          expect(form).to have_field("edition[instructions_to_publishers]")
          expect(form).to have_button("Save and continue")
        end
      end

      it "contains character-limited fields with the correct character limits" do
        expect(page).to have_css(".govuk-character-count[data-module='govuk-character-count'][data-maxlength='65']")
        expect(page).to have_css(".govuk-character-count__message", text: "You can enter up to 65 characters")

        expect(page).to have_css(".govuk-character-count[data-module='govuk-character-count'][data-maxlength='165']")
        expect(page).to have_css(".govuk-character-count__message", text: "You can enter up to 165 characters")
      end

      it "initialises a time period edition with a time period document" do
        edition = assigns(:edition)

        expect(edition).to be_a(V2::TimePeriodEdition)
        expect(edition).to be_new_record
        expect(edition.document).to be_new_record
        expect(edition.document.block_type).to eq("time_period")
      end
    end
  end

  describe "POST /v2/time_period_edition/:id" do
    before do
      allow(Organisation).to receive(:all).and_return([])
    end

    context "with valid parameters" do
      let(:valid_params) do
        {
          edition: {
            title: "Test Time Period Edition",
            description: "This is a test time period edition.",
            lead_organisation_id: SecureRandom.uuid,
            instructions_to_publishers: "Please follow the instructions.",
          },
        }
      end

      it "creates a new time period edition and redirects to the date range page" do
        expect {
          post v2_time_period_editions_path, params: valid_params
        }.to change(V2::TimePeriodEdition, :count).by(1)

        expected_created_edition = V2::TimePeriodEdition.last

        expect(response).to redirect_to(edit_v2_time_period_edition_time_period_date_range_path(expected_created_edition))
        follow_redirect!
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        {
          edition: {
            title: "", # Invalid because title is required
            lead_organisation_id: nil, # Invalid because lead_organisation_id is required
          },
        }
      end

      it "does not create a new time period edition and re-renders the form with errors" do
        expect {
          post v2_time_period_editions_path, params: invalid_params
        }.not_to change(V2::TimePeriodEdition, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response).to render_template("v2/time_period_editions/new")

        expect(page).to have_css(".gem-c-error-summary__list-item", text: "Title cannot be blank")
        expect(page).to have_css(".gem-c-error-summary__list-item", text: "Lead organisation cannot be blank")

        expect(page).to have_css(".govuk-error-message", text: "Title cannot be blank")
        expect(page).to have_css(".govuk-error-message", text: "Lead organisation cannot be blank")
      end
    end
  end

  describe "PUT /v2/documents/:docucment_id/editions/:id" do
    let(:existing_params) do
      { title: "Existing Edition",
        description: "Existing description",
        lead_organisation_id: SecureRandom.uuid,
        instructions_to_publishers: "Existing instructions" }
    end

    let(:updated_params) do
      { title: "Updated Edition",
        description: "Updated description",
        lead_organisation_id: SecureRandom.uuid,
        instructions_to_publishers: "Updated instructions" }
    end

    let(:invalid_params) do
      { title: "",
        description: "",
        lead_organisation_id: nil,
        instructions_to_publishers: "" }
    end

    let(:existing_edition) { create(:v2_time_period_edition, **existing_params) }

    let(:updated_edition) { create(:v2_time_period_edition, **updated_params) }

    let(:lead_organisation) { build(:organisation, id: SecureRandom.uuid) }

    before do
      allow(Organisation).to receive(:all).and_return([])
    end

    it "updates an existing time period edition" do
      put v2_document_edition_path(existing_edition.document, existing_edition), params: { edition: updated_params }

      existing_edition.reload
      expect(existing_edition.title).to eq(updated_params[:title])
      expect(existing_edition.description).to eq(updated_params[:description])
      expect(existing_edition.lead_organisation_id).to eq(updated_params[:lead_organisation_id])
      expect(existing_edition.instructions_to_publishers).to eq(updated_params[:instructions_to_publishers])
    end

    context "when the edition has no associated date range" do
      let(:edition_without_date_range) { create(:v2_time_period_edition, date_range: nil, lead_organisation_id: lead_organisation.id) }

      before do
        allow(Organisation).to receive(:find).and_return(lead_organisation)
      end

      it "redirects to the edit date range page" do
        put v2_document_edition_path(edition_without_date_range.document, edition_without_date_range), params: { edition: updated_params }

        expect(response).to redirect_to(edit_v2_time_period_edition_time_period_date_range_path(edition_without_date_range))
        follow_redirect!
      end
    end

    context "when the edition has an associated date range" do
      let(:edition_with_date_range) { create(:v2_time_period_edition, date_range: build(:v2_time_period_date_range), lead_organisation_id: lead_organisation.id) }

      before do
        allow(Organisation).to receive(:find).and_return(lead_organisation)
      end

      it "redirects to the pre publication review page with a success message" do
        put v2_document_edition_path(edition_with_date_range.document, edition_with_date_range), params: { edition: updated_params }
        expect(response).to redirect_to(new_v2_time_period_edition_pre_publication_review_path(edition_with_date_range))
        follow_redirect!
        expect(response.body).to include(I18n.t("v2.time_period_edition.update.success"))
      end
    end

    it "re-renders the edit form with errors when invalid parameters are provided" do
      put v2_document_edition_path(existing_edition.document, existing_edition), params: { edition: invalid_params }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template("v2/time_period_editions/edit")

      expect(page).to have_css(".gem-c-error-summary__list-item", text: "Title cannot be blank")
      expect(page).to have_css(".gem-c-error-summary__list-item", text: "Lead organisation cannot be blank")

      expect(page).to have_css(".govuk-error-message", text: "Title cannot be blank")
      expect(page).to have_css(".govuk-error-message", text: "Lead organisation cannot be blank")
    end
  end
end
