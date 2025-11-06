RSpec.describe Document do
  it "exists with required data" do
    document = create(
      :document,
      :pension,
      content_id: "52084b2d-4a52-4e69-ba91-3052b07c7eb6",
      sluggable_string: "Title",
      created_at: Time.zone.local(2000, 12, 31, 23, 59, 59).utc,
      updated_at: Time.zone.local(2000, 12, 31, 23, 59, 59).utc,
    )

    aggregate_failures do
      expect("52084b2d-4a52-4e69-ba91-3052b07c7eb6").to eq(document.content_id)
      expect("Title").to eq(document.sluggable_string)
      expect("pension").to eq(document.block_type)
      expect(Time.zone.local(2000, 12, 31, 23, 59, 59).utc).to eq(document.created_at)
      expect(Time.zone.local(2000, 12, 31, 23, 59, 59).utc).to eq(document.updated_at)
      expect("title").to eq(document.content_id_alias)
    end
  end

  it "does not allow the block type to be changed" do
    document = create(:document, :pension)

    expect {
      document.update(block_type: "something_else")
    }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "can store the id of the latest edition" do
    document = create(:document, :pension)
    document.update!(latest_edition_id: 1)

    expect(document.reload.latest_edition_id).to eq(1)
  end

  it "can store the id of the live edition" do
    document = create(:document, :pension)
    document.update!(live_edition_id: 1)

    expect(document.reload.live_edition_id).to eq(1)
  end

  it "gets its version history from its editions" do
    document = create(:document, :pension)
    edition = create(
      :edition,
      document:,
      creator: create(:user),
    )
    document.update!(editions: [edition])

    expect(document.versions.first.item.id).to eq(edition.id)
  end

  describe "embed_code" do
    let(:content_id) { SecureRandom.uuid }
    let(:content_id_alias) { "some-alias" }
    let(:document) { create(:document, :pension, content_id:, content_id_alias:) }

    it "returns embed code for the document" do
      expect(document.embed_code).to eq("{{embed:content_block_pension:#{content_id_alias}}}")
    end

    it "returns embed code for a particular field" do
      expect(document.embed_code_for_field("rates/rate2/name")).to eq(
        "{{embed:content_block_pension:#{content_id_alias}/rates/rate2/name}}",
      )
    end
  end

  describe "latest_edition" do
    let(:document) { create(:document, :pension) }

    let(:latest_edition_1) { create(:edition, document: document) }
    let(:latest_edition_2) { create(:edition, document: document) }

    context "when the #latest_edition_id FK is set" do
      before do
        document.update!(latest_edition_id: latest_edition_1.id)
      end

      it "returns the associated edition" do
        expect(document.reload.latest_edition).to eq(latest_edition_1)

        document.update!(latest_edition_id: latest_edition_2.id)

        expect(document.reload.latest_edition).to eq(latest_edition_2)
      end
    end

    context "when the latest_edition_id FK is NOT set" do
      before do
        document.update!(latest_edition_id: nil)
      end

      it "returns nil" do
        expect(document.reload.latest_edition).to be_nil
      end
    end

    context "when an edition is assigned using latest_edition=" do
      before do
        document.latest_edition = latest_edition_1
      end

      it "does NOT set the given edition to be returned as #latest_edition" do
        expect(document.latest_edition_id).to be_nil
        expect(document.reload.latest_edition).to be_nil

        document.latest_edition = latest_edition_2

        expect(document.latest_edition_id).to be_nil
        expect(document.reload.latest_edition).to be_nil
      end
    end
  end

  describe "#most_recent_edition" do
    let(:document) { create(:document, :pension) }

    before do
      create(:edition, document: document, created_at: "2025-01-01", state: "superseded")
      create(:edition, document: document, created_at: "2025-03-01", state: "draft")
      create(:edition, document: document, created_at: "2025-02-01", state: "published")
    end

    it "returns the most recently created edition, regardless of state " do
      expect(document.most_recent_edition.state).to eq("draft")
    end
  end

  describe ".live" do
    it "only returns documents with a latest edition" do
      document_with_latest_edition = create(:document, :pension)
      latest_edition = create(:edition, document: document_with_latest_edition)
      document_with_latest_edition.latest_edition_id = latest_edition.id
      document_with_latest_edition.save!

      create(:document, :pension, latest_edition_id: nil)

      expect(Document.live).to eq([document_with_latest_edition])
    end
  end

  describe "friendly_id" do
    it "generates a content_id_alias" do
      document = create(
        :document,
        :pension,
        sluggable_string: "This is a title",
      )

      expect(document.content_id_alias).to eq("this-is-a-title")
    end

    it "ensures content_id_aliases are unique" do
      documents = create_list(
        :document,
        2,
        :pension,
        sluggable_string: "This is a title",
      )

      expect(documents[0].content_id_alias).to eq("this-is-a-title")
      expect(documents[1].content_id_alias).to eq("this-is-a-title--2")
    end

    it "does not change the alias if the sluggable string changes" do
      document = create(
        :document,
        :pension,
        sluggable_string: "This is a title",
      )

      document.sluggable_string = "Something else"
      document.save!

      expect(document.content_id_alias).to eq("this-is-a-title")
    end
  end

  describe "title" do
    it "returns the latest edition's title" do
      document = create(:document, :pension)
      _oldest_edition = create(:edition, document:)
      latest_edition = create(:edition, :latest, document:, title: "I am the latest edition")

      expect(document.title).to eq(latest_edition.title)
    end
  end

  describe "#is_new_block?" do
    it "returns true when there is one associated edition" do
      document = create(:document, :pension, editions: create_list(:edition, 1, :pension))

      expect(document.is_new_block?).to be true
    end

    it "returns false when there is more than one associated edition" do
      document = create(:document, :pension, editions: create_list(:edition, 2, :pension))

      expect(document.is_new_block?).to be false
    end
  end

  describe "#has_newer_draft?" do
    let(:document) { create(:document, :pension) }

    it "returns false when the newest edition is the same as the latest edition" do
      _older_edition = create(:edition, :pension, created_at: Time.zone.now - 2.days, document:)
      edition = create(:edition, :pension, created_at: Time.zone.now, document:)
      document.latest_edition_id = edition.id
      document.save!

      expect(document.has_newer_draft?).to be false
    end

    it "returns true when the newest edition is not the same as the latest edition" do
      edition = create(:edition, :pension, created_at: Time.zone.now - 2.days, document:)
      _newer_edition = create(:edition, :pension, created_at: Time.zone.now, document:)
      document.latest_edition_id = edition.id
      document.save!

      expect(document.has_newer_draft?).to be true
    end
  end

  describe "#latest_draft" do
    let(:document) { create(:document, :pension) }

    it "returns the latest draft edition" do
      _older_draft = create(:edition, :pension, created_at: Time.zone.now - 2.days, document:, state: "draft")
      newest_draft = create(:edition, :pension, created_at: Time.zone.now - 1.day, document:, state: "draft")
      _newest_edition = create(:edition, :pension, created_at: Time.zone.now, document:, state: "published")

      expect(document.latest_draft).to eq(newest_draft)
    end
  end

  describe "#schema" do
    let(:document) { build(:document, :pension) }
    let(:schema) { build(:schema) }

    before do
      # remove the stubbing set in factory
      allow(document).to receive(:schema).and_call_original
    end

    it "returns a schema object" do
      allow(Schema).to receive(:find_by_block_type)
        .with(document.block_type)
        .and_return(schema)

      expect(document.schema).to eq(schema)
    end
  end
end
