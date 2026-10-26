class Edition::Show::V2::ReviewSummaryCardComponent < ViewComponent::Base
  def initialize(edition:)
    @edition = edition
    @document = edition.document
  end

  def block_name
    @document.block_type.humanize
  end

  def title
    "#{block_name} details"
  end

  def rows
    [
      { key: "#{block_name} name", value: @edition.title },
      { key: "Description", value: @edition.description },
      { key: "Lead organisation", value: @edition.lead_organisation.name },
      { key: "Instructions to publishers", value: instructions_value },
    ]
  end

  def summary_card_actions
    [
      {
        label: "Edit",
        href: edit_v2_document_edition_path(@document, @edition),
      },
    ]
  end

private

  def instructions_value
    @edition.instructions_to_publishers.presence || "None"
  end
end
