RSpec.describe FindAndReplaceEmbedCodesService do
  it "finds and replaces embed codes" do
    document_1 = create(:document, :pension, content_id_alias: "something")
    edition_1 = create(:edition, :pension, :latest, state: "published", document: document_1)
    document_1.latest_edition = edition_1
    document_1.save!

    document_2 = create(:document, :pension, content_id_alias: "something-else")
    edition_2 = create(:edition, :pension, :latest, state: "published", document: document_2)
    document_2.latest_edition = edition_2
    document_2.save!

    html = "
      <p>Hello there</p>
      <p>#{edition_2.document.embed_code}</p>
      <p>#{edition_1.document.embed_code}</p>
      <p>#{edition_2.document.embed_code}</p>
    "

    expected = "
      <p>Hello there</p>
      <p>#{edition_2.render(edition_2.document.embed_code)}</p>
      <p>#{edition_1.render(edition_1.document.embed_code)}</p>
      <p>#{edition_2.render(edition_2.document.embed_code)}</p>
    "

    result = FindAndReplaceEmbedCodesService.call(html)

    expect(result).to eq(expected)
  end

  it "ignores blocks that aren't present in the database" do
    edition = create(:edition, :pension)

    html = edition.document.embed_code

    result = FindAndReplaceEmbedCodesService.call(html)
    expect(result).to eq(html)
  end

  it "ignores blocks that don't have a live version" do
    edition = create(:edition, :pension, state: "draft")

    html = edition.document.embed_code

    result = FindAndReplaceEmbedCodesService.call(html)
    expect(result).to eq(html)
  end
end
