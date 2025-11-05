class Editions::HostContentController < BaseController
  def preview
    host_content_id = params[:host_content_id]
    @edition = Edition.find(params[:id])
    @preview_content = PreviewContent.for_content_id(
      content_id: host_content_id,
      edition: @edition,
      base_path: params[:base_path],
      locale: params[:locale],
    )
  end

  def form_handler
    form_handler = PreviewFormHandlerService.new(
      url: params[:url].to_s,
      form_body: params.permit(body: {}).fetch(:body).to_h,
      method: params[:method].to_s,
    )
    edition = Edition.find(params[:id])

    redirect_to host_content_preview_edition_path(
      id: edition.id,
      host_content_id: params[:host_content_id],
      locale: params[:locale],
      base_path: form_handler.response_location_path,
    )
  rescue PreviewFormHandlerService::UnexpectedResponseError, PreviewFormHandlerService::UnexpectedUrlError
    head :bad_request
  end
end
