def initial_details
  OpenStruct.new({
    title: "New Time Period Edition",
    date_range: {
      start: Time.zone.parse("2026-07-02T23:30:00+01:00"),
      end: Time.zone.parse("2026-07-28T00:00:00+01:00"),
    },
    description: "This is a new time period edition.",
    instructions_to_publishers: "Nothing much.",
  })
end

def updated_details
  OpenStruct.new({
    title: "Updated edition title",
    date_range: {
      start: Time.zone.parse("2027-08-01T00:00:00+01:00"),
      end: Time.zone.parse("2027-08-31T23:30:00+01:00"),
    },
  })
end

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
    title: initial_details.title,
    description: initial_details.description,
    lead_organisation_id: organisation.id,
    instructions_to_publishers: initial_details.instructions_to_publishers,
    date_range: FactoryBot.build(:v2_time_period_date_range, start: initial_details.date_range[:start], end: initial_details.date_range[:end]),
  )
  puts "Created Time Period Edition with ID: #{@time_period_edition.id}"
end

And("that edition is published") do
  @time_period_edition.publish!
end

And("a date range exists for that time period") do
  FactoryBot.create(
    :v2_time_period_date_range,
    edition: @time_period_edition,
    start: 1.month.ago,
    end: 1.month.from_now,
  )
end

And("I am viewing the show document page for that time period") do
  @document = @time_period_edition.document
  visit v2_document_path(@document)
end

And("I see the Time Period Edition fields pre-populated with the existing edition's data") do
  expect(page).to have_field("edition[title]", with: initial_details.title)
  expect(page).to have_select("edition[lead_organisation_id]", selected: @time_period_edition.lead_organisation.name)
  expect(page).to have_field("edition[description]", with: initial_details.description)
  expect(page).to have_field("edition[instructions_to_publishers]", with: initial_details.instructions_to_publishers)
end

Then("I see the Time Period Date Range fields pre-populated with the existing date range's data") do
  start_time = initial_details.date_range[:start]

  expect(page).to have_select("edition[date_range_attributes][start(5i)]", selected: sprintf("%02d", start_time.min))
  expect(page).to have_select("edition[date_range_attributes][start(4i)]", selected: sprintf("%02d", start_time.hour))
  expect(page).to have_field("edition[date_range_attributes][start(3i)]", with: start_time.day)
  expect(page).to have_field("edition[date_range_attributes][start(2i)]", with: start_time.month)
  expect(page).to have_field("edition[date_range_attributes][start(1i)]", with: start_time.year)

  end_time = initial_details.date_range[:end]

  expect(page).to have_select("edition[date_range_attributes][end(5i)]", selected: sprintf("%02d", end_time.min))
  expect(page).to have_select("edition[date_range_attributes][end(4i)]", selected: sprintf("%02d", end_time.hour))
  expect(page).to have_field("edition[date_range_attributes][end(3i)]", with: end_time.day)
  expect(page).to have_field("edition[date_range_attributes][end(2i)]", with: end_time.month)
  expect(page).to have_field("edition[date_range_attributes][end(1i)]", with: end_time.year)
end

When("I update the date range") do
  start_time = updated_details.date_range[:start]

  select(sprintf("%02d", start_time.min), from: "edition[date_range_attributes][start(5i)]")
  select(sprintf("%02d", start_time.hour), from: "edition[date_range_attributes][start(4i)]")
  fill_in "edition[date_range_attributes][start(3i)]", with: start_time.day
  fill_in "edition[date_range_attributes][start(2i)]", with: start_time.month
  fill_in "edition[date_range_attributes][start(1i)]", with: start_time.year

  end_time = updated_details.date_range[:end]

  select(sprintf("%02d", end_time.min), from: "edition[date_range_attributes][end(5i)]")
  select(sprintf("%02d", end_time.hour), from: "edition[date_range_attributes][end(4i)]")
  fill_in "edition[date_range_attributes][end(3i)]", with: end_time.day
  fill_in "edition[date_range_attributes][end(2i)]", with: end_time.month
  fill_in "edition[date_range_attributes][end(1i)]", with: end_time.year
end

And("I update the edition title") do
  fill_in "edition[title]", with: updated_details.title
end

Then("I see which Time Period Edition errors I need to correct") do
  expect(page).to have_content("Title cannot be blank")
  expect(page).to have_content("Lead organisation cannot be blank")
end

And("I see that the edition was published successfully") do
  expect(page).to have_content(I18n.t("v2.edition.publish.success"))
end

And("the updated title should be shown") do
  expect(page).to have_content(updated_details.title)
end

And("I see that the document's edition and date range have been updated with the details that I entered") do
  expect(page).to have_content(updated_details.title)
  expect(page).to have_content(updated_details.date_range[:start].strftime("%-d %B %Y"))
  expect(page).to have_content(updated_details.date_range[:end].strftime("%-d %B %Y"))
end

And("I fill the Time Period Date Range details with invalid data") do
  fill_in "edition[date_range_attributes][start(1i)]", with: "Invalid"
  fill_in "edition[date_range_attributes][end(1i)]", with: "Invalid"
end

Then("I see errors telling me I have not entered valid dates") do
  expect(page).to have_content("Start date is not a valid date")
  expect(page).to have_content("End date is not a valid date")
end

def fill_in_edition_details(title:, description:, lead_organisation:, instructions:)
  fill_in "edition[title]", with: title
  fill_in "Description", with: description
  select lead_organisation, from: "Lead organisation"
  fill_in "Instructions to publishers", with: instructions
end
