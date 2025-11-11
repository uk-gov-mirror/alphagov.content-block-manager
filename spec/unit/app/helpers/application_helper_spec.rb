RSpec.describe ApplicationHelper, type: :helper do
  describe "#get_content_id" do
    it "returns nil if edition is nil" do
      expect(get_content_id(nil)).to be_nil
    end

    it "returns nil if edition does not respond to `content_id`" do
      edition = double("edition")
      allow(edition).to receive(:respond_to?).with("content_id").and_return(false)

      expect(get_content_id(edition)).to be_nil
    end

    it "returns the content_id if present" do
      content_id = SecureRandom.uuid
      edition = double("edition", content_id:)
      expect(get_content_id(edition)).to eq(content_id)
    end
  end

  describe "#add_indefinite_article" do
    it "prepends word with 'an' when a word starts with a vowel" do
      %w[
        apple
        egg
        igloo
        office
        unlikely
      ].each do |word|
        expect(add_indefinite_article(word)).to eq("an #{word}")
      end
    end

    it "prepends word with 'a' when a word does not start with a vowel" do
      %w[
        bike
        car
        dog
        flag
        goat
      ].each do |word|
        expect(add_indefinite_article(word)).to eq("a #{word}")
      end
    end
  end

  describe "#linked_author" do
    let(:user) { build(:user) }

    it "links to an author if set" do
      expect(linked_author(user)).to eq(link_to(user.name, user_path(user.uid), {}))
    end

    it "passes link options to link_to" do
      expect(
        linked_author(user, { class: "my-link" }),
      ).to eq(
        link_to(user.name, user_path(user.uid), { class: "my-link" }),
      )
    end

    it "returns an unlinked user name if the user does not have a uuid" do
      user.uid = nil
      expect(linked_author(user)).to eq(user.name)
    end

    it "returns a dash if user is not set" do
      expect(linked_author(nil)).to eq("-")
    end
  end

  describe "#taggable_organisations_container" do
    let(:organisations) { build_list(:organisation, 3) }

    before do
      allow(Organisation).to receive(:all).and_return(organisations)
    end

    it "returns all organisations" do
      expected = [
        {
          text: organisations[0].name,
          value: organisations[0].id,
          selected: false,
        },
        {
          text: organisations[1].name,
          value: organisations[1].id,
          selected: false,
        },
        {
          text: organisations[2].name,
          value: organisations[2].id,
          selected: false,
        },
      ]

      expect(taggable_organisations_container([])).to eq(expected)
    end

    it "marks selected organisations" do
      expected = [
        {
          text: organisations[0].name,
          value: organisations[0].id,
          selected: false,
        },
        {
          text: organisations[1].name,
          value: organisations[1].id,
          selected: false,
        },
        {
          text: organisations[2].name,
          value: organisations[2].id,
          selected: true,
        },
      ]

      expect(taggable_organisations_container([organisations[2].id])).to eq(expected)
    end
  end
end
