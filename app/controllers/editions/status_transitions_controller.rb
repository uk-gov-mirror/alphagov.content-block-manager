class Editions::StatusTransitionsController < BaseController
  class UnknownTransitionError < RuntimeError; end

  def create
    @edition = Edition.find(params[:id])
    begin
      attempt_transition!(transition: params.fetch(:transition))
      handle_success
    rescue Transitions::InvalidTransition => e
      handle_failure(e)
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

  def handle_success
    @result = OpenStruct.new(
      outcome: :success,
      message: "Edition #{@edition.id} has been moved into state '#{@edition.state}'",
    )
  end

  def handle_failure(error)
    @result = OpenStruct.new(
      outcome: :failure,
      message: "Error: we can not change the status of this edition. #{error.message}",
    )
  end
end
