RSpec.describe "V2::TimePeriodDateRange", type: :request do
  setup do
    logout
    user = create(:user)
    login_as(user)
  end

  describe "PATCH /v2/documents/:document_id/editions/:id/date-range" do
    let(:edition) do
      create(:v2_time_period_edition, title: "Old Title", description: "Old")
    end
    let(:document) { edition.document }

    let(:start_date) { "2025-04-06 09:00" }
    let(:end_date) { "2026-04-05 17:30" }

    let(:valid_date_range_attributes) do
      {
        edition: {
          date_range_attributes: {
            start: start_date,
            end: end_date,
          },
        },
      }
    end

    let(:invalid_date_range_attributes) do
      {
        edition: {
          date_range_attributes: {
            start: "2026-04-06 09:00",
            end: "2025-04-05 17:30", # End before start
          },
        },
      }
    end

    context "with valid parameters" do
      context "when there is no existing date range associated with the edition" do
        it "creates and associates the date range with the edition" do
          patch v2_document_edition_date_range_path(document, edition),
                params: valid_date_range_attributes

          edition.reload
          expect(edition.date_range).to be_present
          expect(edition.date_range.start).to eq(Time.zone.parse(start_date))
          expect(edition.date_range.end).to eq(Time.zone.parse(end_date))
        end

        it "redirects to the review path with the creation success message" do
          patch v2_document_edition_date_range_path(document, edition),
                params: valid_date_range_attributes

          expect(response).to redirect_to(new_v2_document_edition_pre_publication_review_path(document, edition))
          expect(flash[:success]).to eq(I18n.t("v2.time_period_edition.create.success"))
        end
      end

      context "when there is an existing date range associated with the edition" do
        let!(:existing_date_range) do
          create(
            :v2_time_period_date_range,
            edition: edition,
            start: start_date,
            end: end_date,
          )
        end

        let(:updated_start_date) { "2025-04-06 09:00" }
        let(:updated_end_date) { "2026-04-05 17:30" }

        let(:update_params) do
          {
            edition: {
              date_range_attributes: {
                id: existing_date_range.id,
                start: updated_start_date,
                end: updated_end_date,
              },
            },
          }
        end

        it "updates the existing date range in place" do
          expect {
            patch v2_document_edition_date_range_path(document, edition),
                  params: update_params
          }.not_to change(existing_date_range.class, :count)

          existing_date_range.reload
          expect(existing_date_range.start).to eq(Time.zone.parse(updated_start_date))
          expect(existing_date_range.end).to eq(Time.zone.parse(updated_end_date))
        end

        it "redirects to the review path with the update success message" do
          patch v2_document_edition_date_range_path(document, edition),
                params: update_params

          expect(response).to redirect_to(new_v2_document_edition_pre_publication_review_path(document, edition))
          expect(flash[:success]).to eq(I18n.t("v2.time_period_edition.update.success"))
        end
      end
    end

    context "with invalid parameters" do
      it "does not update the edition" do
        original_start = edition.date_range&.start
        patch v2_document_edition_date_range_path(document, edition),
              params: invalid_date_range_attributes
        edition.reload
        expect(edition.date_range&.start).to eq(original_start)
      end

      it "returns unprocessable content status" do
        patch v2_document_edition_date_range_path(document, edition),
              params: invalid_date_range_attributes
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders the edit template" do
        patch v2_document_edition_date_range_path(document, edition),
              params: invalid_date_range_attributes
        expect(response).to render_template(:edit)
      end
    end
  end
end
