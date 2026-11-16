module Edition::Workflow
  extend ActiveSupport::Concern
  include DateValidation

  class ReviewOutcomeMissingError < RuntimeError; end
  class WorkflowCompletionError < RuntimeError; end

  included do
    include ActiveRecord::Transitions

    class << self
      def active_states
        available_states - inactive_states
      end

      def inactive_states
        %i[superseded deleted]
      end

      def in_progress_states
        available_states - finalised_states
      end

      def finalised_states
        %i[published superseded deleted]
      end
    end

    date_attributes :scheduled_publication

    validates_with ScheduledPublicationValidator, if: -> { validation_context == :scheduling || state == "scheduled" }

    state_machine auto_scopes: true do
      state :draft
      state :draft_complete
      state :published
      state :scheduled
      state :superseded
      state :awaiting_review
      state :awaiting_factcheck
      state :deleted

      event :publish do
        transitions from: %i[draft draft_complete awaiting_review awaiting_factcheck scheduled], to: :published
      end
      event :schedule do
        transitions from: %i[draft draft_complete awaiting_factcheck], to: :scheduled
      end
      event :supersede do
        transitions from: %i[scheduled], to: :superseded
      end
      event :complete_draft do
        transitions from: %i[draft], to: :draft_complete
      end
      event :ready_for_review do
        transitions from: %i[draft_complete], to: :awaiting_review
      end
      event :ready_for_factcheck do
        transitions from: %i[awaiting_review], to: :awaiting_factcheck, guard: [:has_review_outcome_recorded?]
      end
      event :delete, success: lambda { |edition|
        DeleteEditionService.new.call(edition)
      } do
        transitions from: %i[draft draft_complete awaiting_review awaiting_factcheck scheduled], to: :deleted
      end
    end

    def event_fired(current_state, new_state, event)
      version = Version.increment_for_edition(
        edition: self,
        user: Current.user,
        state: new_state,
        field_diffs: generate_diff,
      )

      DomainEvent.record(
        document: document,
        edition: self,
        user: Current.user,
        version: version,
        name: "edition.state_transition.succeeded",
        metadata: {
          previous_state: current_state,
          new_state: new_state,
          transition_name: event,
          scheduled_publication: (scheduled_publication.to_fs(:long_ordinal_with_at) if new_state == :scheduled),
        }.compact,
      )
    end

    def has_review_outcome_recorded?
      return true if review_outcome.present?

      error_message = "Edition #{id} does not have a 2i Review outcome recorded and so " \
        "can't transition into the 'awaiting_factcheck' state"
      raise ReviewOutcomeMissingError, error_message
    end

    def in_progress?
      state.to_sym.in?(self.class.in_progress_states)
    end
  end
end
