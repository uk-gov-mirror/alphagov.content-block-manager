module V2
  class PrePublicationReviewsController < BaseController
    before_action :set_edition, :set_document
    helper_method :page_title

    def new; end

    def create
      unless params.dig(:edition, :has_checked_content)
        @check_content_error_copy = I18n.t(
          "v2.edition.pre_publication_review.errors.confirm",
        )

        return render "v2/pre_publication_reviews/new", status: :unprocessable_content
      end

      completion = V2::WorkflowCompletionService.new(@edition, "publish").call

      redirect_to completion[:path], flash: completion[:flash]
    end

  private

    def set_edition
      edition_id = params[:time_period_edition_id]

      @edition = V2::Edition.find(edition_id)
    end

    def set_document
      @document = @edition.document
    end

    def page_title
      block_name = @edition.document.block_type.humanize.downcase
      "Review #{block_name}"
    end
  end
end
