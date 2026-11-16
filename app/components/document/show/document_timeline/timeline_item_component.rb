require "record_tag_helper/helper"

class Document::Show::DocumentTimeline::TimelineItemComponent < ViewComponent::Base
  include ActionView::Helpers::RecordTagHelper

  def initialize(domain_event:, schema:, is_first_published_version:, is_latest:)
    @domain_event = domain_event
    @schema = schema
    @is_first_published_version = is_first_published_version
    @is_latest = is_latest
  end

private

  attr_reader :domain_event, :schema, :is_first_published_version, :is_latest

  def version
    domain_event.version
  end

  def edition
    domain_event.edition
  end

  def title
    return I18n.t("domain_event.title.#{domain_event.name}") unless version

    case version.state
    when "published"
      if is_first_published_version
        I18n.t("timeline_item.title.published", block_type: version.item.block_type.humanize)
      else
        version.state.capitalize
      end
    when "scheduled"
      I18n.t("timeline_item.title.scheduled", datetime_string: datetime_string)
    when "draft_complete"
      I18n.t("timeline_item.title.draft_complete")
    when "awaiting_review"
      I18n.t("timeline_item.title.awaiting_review")
    when "awaiting_factcheck"
      I18n.t("timeline_item.title.awaiting_factcheck")
    else
      "#{version.item.block_type.humanize} #{version.state}"
    end
  end

  def datetime_string
    # For V1 we need a bit of logic here to handle historic Version/Domain Event pairs created before the update to DomainEvent metadata population
    if domain_event.metadata.key?("scheduled_publication")
      "on #{domain_event.metadata['scheduled_publication']}"
    elsif version.item.scheduled_publication
      "on #{version.item.scheduled_publication.to_fs(:long_ordinal_with_at)}"
    else
      # Backup to prevent exception for Version/DomainEvent pairs which would have been affected by the bug caused by manual publishing
      ""
    end
  end

  def outcome
    version ? version_outcome : domain_event_outcome
  end

  def outcome_resolution
    version ? version_outcome_resolution : domain_event_outcome_resolution
  end

  def version_outcome
    case version.state
    when "awaiting_factcheck"
      version.item.review_outcome
    when "published"
      version.item.fact_check_outcome
    end
  end

  def version_outcome_resolution
    review_name = I18n.t("timeline_item.outcome.name.review")
    fact_check_name = I18n.t("timeline_item.outcome.name.fact_check")

    review_type = version.state == "awaiting_factcheck" ? review_name : fact_check_name
    skipped_or_performed = outcome.skipped ? "skipped" : "performed"
    performer = outcome.performer ? " by #{outcome.performer.try(:name) || outcome.performer}" : ""

    "#{review_type} #{skipped_or_performed}#{performer}"
  end

  def domain_event_outcome
    %w[
      edition.review.performed
      edition.review.skipped
      edition.fact_check.performed
      edition.fact_check.skipped
    ].include?(domain_event.name)
  end

  def domain_event_outcome_resolution
    if domain_event.metadata["performer"].present?
      I18n.t("domain_event.body.#{domain_event.name}_with_performer", performer: domain_event.metadata["performer"])
    else
      I18n.t("domain_event.body.#{domain_event.name}")
    end
  end

  def date
    tag.time(
      domain_event.created_at.to_fs(:long_ordinal_with_at),
      class: "date",
      datetime: domain_event.created_at.iso8601,
      lang: "en",
    )
  end

  def byline
    User.find_by_id(domain_event.user_id)&.then { |user| helpers.linked_author(user, { class: "govuk-link" }) } || "unknown user"
  end

  def internal_change_note
    edition.internal_change_note
  end

  def change_note
    edition.change_note
  end

  def embedded_object_diffs
    schema.subschemas.map { |subschema|
      subschema_diffs = version&.field_diffs&.dig("details", subschema.id)
      next if subschema_diffs.blank?

      if subschema.relationship_type.one_to_one?
        [{
          object_id: subschema.id,
          field_diff: subschema_diffs,
          subschema_id: subschema.id,
        }]
      else
        subschema_diffs.map do |object_id, field_diff|
          {
            object_id: object_id,
            field_diff: field_diff,
            subschema_id: subschema.id,
          }
        end
      end
    }.flatten.compact
  end

  def details_of_changes
    @details_of_changes ||= begin
      return "" if version&.field_diffs.blank?

      [
        main_object_field_changes,
        embedded_object_field_changes,
      ].join.html_safe
    end
  end

  def main_object_field_changes
    render Document::Show::DocumentTimeline::FieldChangesTableComponent.new(
      version:,
      schema:,
    )
  end

  def embedded_object_field_changes
    if embedded_object_diffs.any?
      embedded_object_diffs.map do |item|
        render Document::Show::DocumentTimeline::EmbeddedObject::FieldChangesTableComponent.new(
          **item,
          edition: version.item,
        )
      end
    end
  end
end
