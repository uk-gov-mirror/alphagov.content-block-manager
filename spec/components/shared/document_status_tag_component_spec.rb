RSpec.describe Shared::DocumentStatusTagComponent, type: :component do
  let(:edition) { instance_double(Edition, state: "draft") }
  let(:document) { double(Document, most_recent_edition: edition) }

  let(:component) { described_class.new(document: document) }

  before do
    allow(I18n).to receive(:t).with("edition.states.label.draft").and_return("Translated state")
    allow(I18n).to receive(:t).with("edition.states.colour.draft").and_return("pink")

    render_inline(component)
  end

  it "finds document's most recent edition" do
    expect(document).to have_received(:most_recent_edition)
  end

  it "sets a helpful 'title' attribute" do
    expect(page).to have_css(".govuk-tag[title='Status: Translated state']")
  end

  it "sets  an aria label for screenreaders" do
    expect(page).to have_css(".govuk-tag[aria-label='Status: Translated state']")
  end

  it "displays a translated version of the most recent edition's state" do
    within ".govuk-tag" do
      expect(page).to have_content("Translated state")
    end
  end

  it "sets the colour of the status tag using the translation file" do
    expect(page).to have_css(".govuk-tag--pink")
  end
end
