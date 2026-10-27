module V2
  class WorkflowCompletionService
    include Rails.application.routes.url_helpers

    VALID_SAVE_ACTIONS = {
      "publish" => :publish,
    }.freeze

    class UnhandledSaveActionError < StandardError; end

    def initialize(edition, save_action)
      @edition = edition
      @save_action = save_action
    end

    def call
      validate_action
      send(sanitised_save_action)
    end

  private

    def validate_action
      return true if @save_action.in?(VALID_SAVE_ACTIONS.keys)

      raise UnhandledSaveActionError, "Unknown save action: '#{@save_action}'"
    end

    def sanitised_save_action
      VALID_SAVE_ACTIONS.fetch(@save_action)
    end

    def publish
      if @edition.state != "published"
        begin
          V2::PublishEditionService.new.call(@edition)
        rescue V2::PublishEditionService::PublishingFailureError => e
          return {
            path: new_v2_document_edition_pre_publication_review_path(@edition.document, @edition),
            flash: { alert: e.message },
          }
        end
      end

      { path: v2_document_path(@edition.document), flash: { success: I18n.t("v2.edition.publish.success") } }
    end
  end
end
