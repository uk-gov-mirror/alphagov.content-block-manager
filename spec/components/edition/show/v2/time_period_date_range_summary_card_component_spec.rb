RSpec.describe Edition::Show::V2::TimePeriodDateRangeSummaryCardComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:start_date) { Date.new(2026, 1, 5) }
  let(:end_date) { Date.new(2026, 12, 25) }
  let(:date_range) { build(:v2_time_period_date_range, start: start_date, end: end_date) }
  let(:edition) { create(:v2_time_period_edition, date_range: date_range) }

  subject(:component) do
    described_class.new(
      edition: edition,
    )
  end

  describe "on render" do
    it "displays the expected title" do
      render_inline(component)

      expect(page).to have_text("Date range details")
    end

    it "displays both dates without zero padding the day" do
      render_inline(component)

      expect(page).to have_summary_row
        .with_key("Start")
        .with_value("5 January 2026")
      expect(page).to have_summary_row
      .with_key("End")
      .with_value("25 December 2026")
    end

    it "renders an edit action link" do
      render_inline(component)

      expected_path = edit_v2_document_edition_date_range_path(edition.document, edition)
      expect(page).to have_link("Edit", href: expected_path)
    end
  end
end
