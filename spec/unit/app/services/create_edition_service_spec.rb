RSpec.describe CreateEditionService do
  describe "#call" do
    let!(:organisation) { build(:organisation) }

    let(:content_id) { "49453854-d8fd-41da-ad4c-f99dbac601c3" }
    let(:schema) { build(:schema, block_type: "content_block_type", body: { "properties" => { "foo" => "", "bar" => "" } }) }
    let(:new_title) { "New Title" }
    let(:edition_params) do
      {
        document_attributes: {
          block_type: "pension",
        }.with_indifferent_access,
        details: {
          "foo" => "Foo text",
          "bar" => "Bar text",
        },
        creator: build(:user),
        lead_organisation_id: organisation.id.to_s,
        title: new_title,
      }
    end

    before do
      # This UUID is created by the database so instead of loading the record
      # we double the initial creation so we know what UUID to check for.
      allow_any_instance_of(Edition).to receive(:create_random_id).and_return(content_id)
      allow(Schema).to receive(:find_by_block_type).and_return(schema)
      allow(Organisation).to receive(:all).and_return([organisation])
    end

    it "returns a ContentBlockEdition" do
      result = CreateEditionService.new(schema).call(edition_params)
      expect(result).to be_a(Edition)
    end

    it "creates a Document" do
      expect { CreateEditionService.new(schema).call(edition_params) }.to change { Document.count }.from(0).to(1)
    end

    it "creates an Edition" do
      expect {
        CreateEditionService.new(schema).call(edition_params)
      }.to change { Edition.count }.from(0).to(1)

      new_document = Document.find_by!(content_id:)
      new_edition = new_document.editions.first

      expect(new_document.block_type).to eq(edition_params[:document_attributes][:block_type])
      expect(new_edition.title).to eq(new_title)
      expect(new_edition.details).to eq(edition_params[:details])
      expect(new_edition.document_id).to eq(new_document.id)
      expect(new_edition.lead_organisation_id).to eq(organisation.id)
    end

    describe "when a document id is provided" do
      let(:document) { create(:document, :pension) }
      let!(:previous_edition) { create(:edition, :pension, :latest, document:) }

      it "does not create a new document" do
        expect {
          CreateEditionService.new(schema).call(edition_params, document_id: document.id)
        }.to_not(change { Document.count })
      end

      it "creates a new edition for that document" do
        expect {
          CreateEditionService.new(schema).call(edition_params, document_id: document.id)
        }.to(change { document.reload.editions.count }.from(1).to(2))

        new_edition = document.editions.last

        expect(new_edition.details).to eq(edition_params.[](:details))
        expect(new_edition.title).to eq(edition_params.[](:title))
        expect(document.id).to eq(new_edition.document_id)
        expect(organisation.id).to eq(new_edition.lead_organisation.id)
      end

      describe "when a previous edition has details that are not provided in the params" do
        let!(:previous_edition) do
          create(
            :edition, :pension, :latest,
            document:,
            details: { "foo" => "Old text", "bar" => "Old text", "something" => { "else" => { "is" => "here" } } }
          )
        end

        it "does not overwrite the non-provided details" do
          CreateEditionService.new(schema).call(edition_params, document_id: document.id)

          new_edition = document.editions.last

          expect(new_edition.title).to eq(edition_params.[](:title))
          expect(document.id).to eq(new_edition.document_id)
          expect(organisation.id).to eq(new_edition.lead_organisation.id)

          expect(new_edition.details.[]("foo")).to eq(edition_params.[](:details).[]("foo"))
          expect(new_edition.details.[]("bar")).to eq(edition_params.[](:details).[]("bar"))
          expect({ "else" => { "is" => "here" } }).to eq(edition_params.[](:details).[]("something"))
        end
      end
    end
  end
end
