RSpec.describe Edition::Show::V2::ReviewSummaryCardComponent, type: :component do
  let(:lead_organisation) { build(:organisation, name: "Department of Health", id: SecureRandom.uuid) }
  let(:document) { build(:v2_document, block_type: "time_period") }
  let(:edition) do
    create(:v2_time_period_edition, title: "2024 to 2025",
                                    description: "Financial year",
                                    lead_organisation_id: lead_organisation.id,
                                    document: document,
                                    instructions_to_publishers: "Published annually")
  end

  subject(:component) { described_class.new(edition: edition) }

  before do
    allow(Organisation).to receive(:find).and_return(lead_organisation)
  end

  describe "#rows" do
    it "maps the edition attributes to the correct key-value pairs" do
      expect(component.rows).to eq([
        { key: "Time period name", value: "2024 to 2025" },
        { key: "Description", value: "Financial year" },
        { key: "Lead organisation", value: "Department of Health" },
        { key: "Instructions to publishers", value: "Published annually" },
      ])
    end

    context "when instructions_to_publishers is blank" do
      before do
        allow(edition).to receive(:instructions_to_publishers).and_return("")
      end

      it "falls back to 'None'" do
        instructions_row = component.rows.find { |r| r[:key] == "Instructions to publishers" }
        expect(instructions_row[:value]).to eq("None")
      end
    end

    context "when instructions_to_publishers is nil" do
      it "falls back to 'None'" do
        edition.instructions_to_publishers = nil
        instructions_row = component.rows.find { |r| r[:key] == "Instructions to publishers" }
        expect(instructions_row[:value]).to eq("None")
      end
    end
  end

  describe "#summary_card_actions" do
    it "generates the correct edit link hash" do
      allow(component).to receive(:edit_v2_document_edition_path).with(document, edition).and_return("/v2/editions/123/edit")

      expect(component.summary_card_actions).to eq([
        { label: "Edit", href: "/v2/editions/123/edit" },
      ])
    end
  end

  describe "rendering" do
    it "renders the summary card with expected content" do
      render_inline(component)

      expect(page).to have_text("Time period details")
      expect(page).to have_summary_row
        .with_key("Time period name")
        .with_value("2024 to 2025")
      expect(page).to have_summary_row
      .with_key("Description")
      .with_value("Financial year")
      expect(page).to have_summary_row
      .with_key("Lead organisation")
      .with_value("Department of Health")
      expect(page).to have_summary_row
      .with_key("Instructions to publishers")
      .with_value("Published annually")

      expect(page).to have_link("Edit")
    end
  end
end
