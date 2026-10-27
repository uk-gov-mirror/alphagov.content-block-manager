RSpec.describe V2::WorkflowCompletionService do
  let(:organisation) { build(:organisation) }
  let(:document) { create(:v2_document, id: 567) }
  let(:edition) do
    create(:v2_edition,
           id: 123,
           document: document,
           lead_organisation_id: organisation.id)
  end
  let(:published_edition) do
    create(:v2_edition,
           id: 456,
           document: document,
           state: "published",
           lead_organisation_id: organisation.id)
  end

  before do
    allow(Organisation).to receive(:all).and_return([organisation])
    allow(Public::Services.publishing_api).to receive(:put_content)
    allow(Public::Services.publishing_api).to receive(:publish)
    allow(V2::DomainEvent).to receive(:record)
    allow(V2::Version).to receive(:increment_for_edition)
  end

  describe "#call" do
    describe "when called with invalid save_actions" do
      it "should raise an error" do
        aggregate_failures do
          expect { described_class.new(edition, "foobar").call }.to raise_error(described_class::UnhandledSaveActionError)
          expect { described_class.new(edition, "").call }.to raise_error(described_class::UnhandledSaveActionError)
        end
      end
    end

    describe "when the save_action is 'publish'" do
      let(:service) { double(V2::PublishEditionService) }

      before do
        allow(V2::PublishEditionService).to receive(:new).and_return(service)
      end

      describe "when the edition has not yet been published" do
        before do
          allow(service).to receive(:call).and_return(edition)
        end

        it "should call the V2::PublishEditionService with the Edition" do
          described_class.new(edition, "publish").call

          expect(service).to have_received(:call).with(edition)
        end

        it "should return the document show page path and success flash message" do
          described_class.new(edition, "publish").call => { path:, flash: }

          expect(path).to eq("/v2/documents/567")
          expect(flash).to eq({ success: I18n.t("v2.edition.publish.success") })
        end
      end

      describe "when the publishing service raises an error" do
        let(:error_message) { "Failed to publish to the publishing API" }

        before do
          allow(service).to receive(:call).and_raise(V2::PublishEditionService::PublishingFailureError, error_message)
        end

        it "should return the pre publication review path and an alert flash message" do
          described_class.new(edition, "publish").call => { path:, flash: }

          expect(path).to eq("/v2/documents/567/editions/123/pre-publication-reviews/new")
          expect(flash).to eq({ alert: error_message })
        end
      end

      describe "when the edition has already been published" do
        let(:service) { double(V2::PublishEditionService) }

        before do
          allow(service).to receive(:call).and_return(published_edition)
        end

        it "should not call the V2::PublishEditionService with the Edition" do
          described_class.new(published_edition, "publish").call

          expect(service).not_to have_received(:call).with(published_edition)
        end

        it "should return the document show page path to redirect to" do
          described_class.new(published_edition, "publish").call => { path:, flash: }
          expect(path).to eq("/v2/documents/567")
          expect(flash).to eq({ success: I18n.t("v2.edition.publish.success") })
        end
      end
    end
  end
end
