When("I am viewing the form to create a new Time Period Edition") do
  visit new_v2_time_period_edition_path
end

When("I am viewing the form to update an existing Time Period Edition") do
  visit edit_v2_document_edition_path(@time_period_edition.document, @time_period_edition)
end

When("I fill the Time Period Edition details correctly") do
  fill_in_edition_details(
    title: "Test Time Period Edition",
    description: "This is a test time period edition.",
    lead_organisation: "Ministry of Example",
    instructions: "Please review and publish.",
  )
end

When("I fill the Time Period Edition details incorrectly") do
  fill_in_edition_details(
    title: "",
    description: "This is a test time period edition.",
    lead_organisation: "",
    instructions: "Please review and publish.",
  )
end

And("I see that the Edition was created successfully") do
  expect(page).to have_content(I18n.t("v2.time_period_edition.create.success"))
end

Then("I see that the Edition was updated successfully") do
  expect(page).to have_content(I18n.t("v2.time_period_edition.update.success"))
end

When("a Time Period Edition exists") do
  @time_period_edition = FactoryBot.create(:v2_time_period_edition)
  organisation = Organisation.all&.find { |org| org.name == "Ministry of Example" }

  @time_period_edition.update!(
    title: "New Time Period Edition",
    description: "This is a new time period edition.",
    lead_organisation_id: organisation.id,
    instructions_to_publishers: "Nothing much.",
    date_range: FactoryBot.build(:v2_time_period_date_range),
  )
  puts "Created Time Period Edition with ID: #{@time_period_edition.id}"
end

And("a date range exists for that time period") do
  FactoryBot.create(
    :v2_time_period_date_range,
    edition: @time_period_edition,
    start: 1.month.ago,
    end: 1.month.from_now,
  )
end

Then("I see which Time Period Edition errors I need to correct") do
  expect(page).to have_content("Title cannot be blank")
  expect(page).to have_content("Lead organisation cannot be blank")
end

And("I see that the edition was published successfully") do
  expect(page).to have_content(I18n.t("v2.edition.publish.success"))
end

def fill_in_edition_details(title:, description:, lead_organisation:, instructions:)
  fill_in "edition[title]", with: title
  fill_in "Description", with: description
  select lead_organisation, from: "Lead organisation"
  fill_in "Instructions to publishers", with: instructions
end
