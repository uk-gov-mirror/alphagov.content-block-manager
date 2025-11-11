Given("a pension content block has been drafted") do
  @content_block = create(
    :edition,
    :pension,
    details: { description: "Some text" },
    creator: @user,
    lead_organisation_id: @organisation.id,
    title: "My pension",
  )
end

Given("a pension content block has been created") do
  @content_blocks ||= []
  @content_block = create(
    :edition,
    :pension,
    details: { description: "Some text" },
    creator: @user,
    lead_organisation_id: @organisation.id,
    title: "My pension",
  )
  Edition::HasAuditTrail.acting_as(@user) do
    @content_block.publish!
  end
  @content_blocks.push(@content_block)
end

Given("a contact content block has been created") do
  @content_blocks ||= []
  @content_block = create(
    :edition,
    :contact,
    details: { description: "Some text" },
    creator: @user,
    lead_organisation_id: @organisation.id,
    title: "My contact",
  )
  Edition::HasAuditTrail.acting_as(@user) do
    @content_block.publish!
  end
  @content_blocks.push(@content_block)
end

Given(/^([^"]*) content blocks of type ([^"]*) have been created with the fields:$/) do |count, block_type, table|
  fields = table.rows_hash
  organisation_name = fields.delete("organisation")
  organisation = Organisation.all.find { |org| org.name == organisation_name }
  title = fields.delete("title") || "title"
  instructions_to_publishers = fields.delete("instructions_to_publishers")

  (1..count.to_i).each do |_i|
    document = create(:document, block_type.to_sym, sluggable_string: title.parameterize(separator: "_"))

    editions = create_list(
      :edition,
      3,
      block_type.to_sym,
      document:,
      lead_organisation_id: organisation.id,
      details: fields,
      creator: @user,
      instructions_to_publishers:,
      title:,
    )

    document.latest_edition = editions.last
    document.save!
  end
end
