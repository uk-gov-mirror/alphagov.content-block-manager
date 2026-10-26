RSpec.describe EditionTypeConstraints do
  let(:edition) { create(:v2_time_period_edition) }

  it "matches when the edition is of the correct type" do
    constraint = described_class.new("V2::TimePeriodEdition")
    expect(constraint.matches?(request_for(id: edition.id.to_s))).to be true
  end

  it "does not matches when the edition is of the correct type" do
    constraint = described_class.new("Edition")
    expect(constraint.matches?(request_for(id: edition.id.to_s))).to be false
  end

  it "will use :edition_id over :id for nested queries" do
    constraint = described_class.new("V2::TimePeriodEdition")
    expect(constraint.matches?(request_for(id: "99999999",
                                           edition_id: edition.id.to_s,
                                           some_other_id: "9999999"))).to be true
  end

  it "will not repeatedly query the database for the edition type in a single request" do
    request = request_for(id: edition.id.to_s)
    described_class.new("Edition").matches?(request)

    expect(V2::Edition).not_to receive(:where)
    expect(described_class.new("V2::TimePeriodEdition").matches?(request)).to be true
  end

  it "returns false for a request lacking :edition_id or :id" do
    constraint = described_class.new("V2::TimePeriodEdition")
    expect(constraint.matches?(request_for(foo: "bar"))).to be false
  end

  it "returns false where edition_id is invalid" do
    constraint = described_class.new("V2::TimePeriodEdition")
    expect(constraint.matches?(request_for(id: "invalid"))).to be false
  end
end
