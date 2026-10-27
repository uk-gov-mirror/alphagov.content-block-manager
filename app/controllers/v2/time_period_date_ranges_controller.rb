module V2
  class TimePeriodDateRangesController < ApplicationController
    before_action :set_edition, :set_document

    def edit; end

    def update
      has_associated_date_range = @edition.date_range.present?

      if @edition.update(edition_params)
        notice_key = has_associated_date_range ? "update.success" : "create.success"
        flash[:success] = I18n.t("v2.time_period_edition.#{notice_key}")

        redirect_to new_v2_document_edition_pre_publication_review_path(@document, @edition)
      else
        @error_summary_errors = @edition.errors.map do |error|
          {
            text: error.message,
            href: "##{error.attribute.to_s.tr('.', '_')}",
          }
        end
        render :edit, status: :unprocessable_content
      end
    end

  private

    def set_edition
      @edition = V2::TimePeriodEdition.find(params[:edition_id])
    end

    def set_document
      @document = V2::Document.find(params[:document_id])
    end

    def edition_params
      params.require(:edition).permit(
        date_range_attributes: %i[id start end],
      )
    end
  end
end
