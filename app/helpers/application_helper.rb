require "record_tag_helper/helper"

module ApplicationHelper
  include ActionView::Helpers::RecordTagHelper

  def pre_release_features?
    env = GovukPublishingComponents::AppHelpers::Environment.current_acceptance_environment
    return false if env == "production"

    return true if current_user.has_permission?(User::Permissions::PRE_RELEASE_FEATURES_PERMISSION)
    return true if params[:pre_release_features] == "true"

    false
  end

  def get_content_id(edition)
    return if edition.nil?

    return unless edition.respond_to?("content_id")

    edition.content_id
  end

  def linked_author(author, link_options = {})
    if author&.uid
      link_to(author.name, user_path(author.uid), link_options)
    else
      author&.name || "-"
    end
  end

  def add_indefinite_article(noun)
    indefinite_article = starts_with_vowel?(noun) ? "an" : "a"
    "#{indefinite_article} #{noun}"
  end

  def starts_with_vowel?(word_or_phrase)
    "aeiou".include?(word_or_phrase.downcase[0])
  end

  def taggable_organisations_container(selected_ids)
    Organisation.all.map do |o|
      {
        text: o.name,
        value: o.id,
        selected: selected_ids.include?(o.id),
      }
    end
  end
end
