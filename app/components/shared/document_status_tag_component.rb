class Shared::DocumentStatusTagComponent < ViewComponent::Base
  def initialize(document:)
    @edition = document.most_recent_edition
  end

  def status
    I18n.t("edition.states.label.#{@edition.state}")
  end

  def colour
    I18n.t("edition.states.colour.#{@edition.state}")
  end
end
