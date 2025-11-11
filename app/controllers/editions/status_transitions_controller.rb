class Editions::StatusTransitionsController < BaseController
  class UnknownTransitionError < RuntimeError; end

  def create
    @edition = Edition.find(params[:id])
    begin
      attempt_transition!(transition: params.fetch(:transition))
      success_message = "Edition #{@edition.id} has been moved into state '#{@edition.state}'"
      @result = OpenStruct.new(outcome: :success, message: success_message)
    rescue Transitions::InvalidTransition => e
      error_message = "Error: we can not change the status of this edition. #{e.message}"
      @result = OpenStruct.new(outcome: :failure, message: error_message)
    ensure
      redirect_to document_path(@edition.document)
    end
  end

private

  def attempt_transition!(transition:)
    case transition.to_sym
    when :ready_for_2i
      @edition.ready_for_2i!
    else
      raise(UnknownTransitionError, "Transition event '#{transition}' is not recognised'")
    end
  end
end
