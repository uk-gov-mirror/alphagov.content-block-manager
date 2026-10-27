class Edition::Show::V2::TimePeriodDateRangeSummaryCardComponent < ViewComponent::Base
  def initialize(edition:)
    @edition = edition
    @document = edition.document
  end

  def title
    "Date range details"
  end

  def rows
    [
      { key: "Start", value: @edition.date_range.start.strftime("%-d %B %Y") },
      { key: "End", value: @edition.date_range.end.strftime("%-d %B %Y") },
    ]
  end

  def summary_card_actions
    [
      {
        label: "Edit",
        href: edit_v2_document_edition_date_range_path(@document, @edition),
      },
    ]
  end
end
