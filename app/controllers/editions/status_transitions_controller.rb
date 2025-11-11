class Editions::StatusTransitionsController < BaseController
  def create
    @edition = Edition.find(params[:id])
    begin
      @edition.ready_for_2i!
      success_message = "Edition #{@edition.id} has been moved into state '#{@edition.state}'"
      @result = OpenStruct.new(outcome: :success, message: success_message)
    rescue Transitions::InvalidTransition => e
      error_message = "Error: we can not change the status of this edition. #{e.message}"
      @result = OpenStruct.new(outcome: :failure, message: error_message)
    ensure
      redirect_to document_path(@edition.document)
    end
  end
end
