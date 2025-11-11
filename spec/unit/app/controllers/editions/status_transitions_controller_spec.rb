RSpec.describe Editions::StatusTransitionsController, type: :controller do
  include LoginHelpers

  describe "#create to transition to 'awaiting_2i'" do
    let(:user) { create :user }
    let(:document) { instance_double(Document, id: 456) }
    let(:edition) { instance_double(Edition, id: 123, document: document, state: double) }

    before do
      login_as(user)
      allow(Edition).to receive(:find).and_return(edition)
      allow(edition).to receive(:ready_for_2i!)
    end

    it "retrieves the given edition" do
      post :create, params: { id: 123, transition: :ready_for_2i }

      expect(Edition).to have_received(:find).with("123")
    end

    it "attempts to transition the given edition to the 'awaiting_2i' state" do
      post :create, params: { id: 123, transition: :ready_for_2i }

      expect(edition).to have_received(:ready_for_2i!)
    end

    context "when the transition succeeds" do
      before do
        allow(edition).to receive(:ready_for_2i!).and_return(true)
        allow(edition).to receive(:state).and_return("awaiting_2i")
      end

      it "redirects to the show page" do
        post :create, params: { id: 123, transition: :ready_for_2i }

        expect(response).to redirect_to(document_path(edition.document))
      end

      it "shows a success message" do
        expected_success_message = "Edition 123 has been moved into state 'awaiting_2i'"

        post :create, params: { id: 123, transition: :ready_for_2i }

        expect(assigns(:result)).to eq(
          OpenStruct.new(
            outcome: :success,
            message: expected_success_message,
          ),
        )
      end
    end

    context "when the transition is invalid" do
      let(:edition_invalid_for_transition) do
        document = create(:document, id: 456)
        create(:edition, state: "awaiting_2i", id: 123, document: document)
      end

      before do
        allow(Edition).to receive(:find).and_return(edition_invalid_for_transition)
      end

      it "redirects to the show page" do
        post :create, params: { id: 123, transition: :ready_for_2i }

        expect(response).to redirect_to(document_path(456))
      end

      it "shows a failure message with the transition error" do
        expected_failure_message = "Error: we can not change the status of this edition. " \
          "Can't fire event `ready_for_2i` in current state `awaiting_2i` for `Edition` with ID 123 "

        post :create, params: { id: 123, transition: :ready_for_2i }

        expect(assigns(:result)).to eq(
          OpenStruct.new(
            outcome: :failure,
            message: expected_failure_message,
          ),
        )
      end
    end

    context "when the transition requested is not recognised" do
      before do
      end

      it "raises an UnknownTransitionError" do
        expect {
          post :create, params: { id: 123, transition: :unknown_transition }
        }.to raise_error(
          Editions::StatusTransitionsController::UnknownTransitionError,
          "Transition event 'unknown_transition' is not recognised'",
        )
      end
    end
  end
end
