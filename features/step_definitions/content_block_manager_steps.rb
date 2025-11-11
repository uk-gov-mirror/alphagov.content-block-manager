require_relative "../support/stubs"
require_relative "../support/helpers"

# Suppress noisy Sidekiq logging in the test output
# Sidekiq.configure_client do |cfg|
#   cfg.logger.level = ::Logger::WARN
# end

Given("I am in the staging or integration environment") do
  ContentBlockManager.stubs(:integration_or_staging?).returns(true)
end

When("I click to create an object") do
  @action = "create"
  click_link "Create content block"
end

When("I click cancel") do
  click_button "Cancel"
end

When("I choose to delete the in-progress draft") do
  click_button "Delete draft"
end

When("I click to save and come back later") do
  click_link "Save for later"
end

When("I click the cancel link") do
  click_link "Cancel"
end

Then(/^I click on page ([^"]*)$/) do |page_number|
  click_link page_number
end

When("I complete the form with the following fields:") do |table|
  fields = table.hashes.first
  @title = fields.delete("title")
  @organisation = fields.delete("organisation")
  @instructions_to_publishers = fields.delete("instructions_to_publishers")
  @details = fields

  fill_in label_for_title(@schema.block_type), with: @title if @title.present?

  select_organisation(@organisation) if @organisation.present?

  fill_in "Instructions to publishers", with: @instructions_to_publishers if @instructions_to_publishers.present?

  fields.keys.each do |k|
    fill_in "edition_details_#{k}", with: @details[k]
  end

  click_save_and_continue
end

Then("the edition should have been created successfully") do
  edition = Edition.all.last

  assert_not_nil edition
  assert_not_nil edition.document

  assert_equal @title, edition.title if @title.present?
  assert_equal @instructions_to_publishers, edition.instructions_to_publishers if @instructions_to_publishers.present?

  @details.keys.each do |k|
    assert_equal edition.details[k], @details[k]
  end
end

And("I should be taken to the confirmation page for a published block") do
  edition = Edition.last

  assert_text I18n.t("edition.confirmation_page.updated.banner", block_type: edition.document.block_type.humanize)
  assert_text I18n.t("edition.confirmation_page.updated.detail")

  expect(page).to have_link(
    "View content block",
    href: document_path(
      edition.document,
    ),
  )
end

And("I should be taken to the confirmation page for a new {string}") do |block_type|
  content_block = Edition.last

  assert_text I18n.t("edition.confirmation_page.created.banner", block_type: block_type.titlecase)
  assert_text I18n.t("edition.confirmation_page.created.detail")

  expect(page).to have_link(
    "View content block",
    href: document_path(
      content_block.document,
    ),
  )
end

When("I click to view the content block") do
  click_link href: document_path(
    Edition.last.document,
  )
end

When("I should be taken to the scheduled confirmation page") do
  edition = Edition.last

  assert_text I18n.t(
    "edition.confirmation_page.scheduled.banner",
    block_type: "Pension",
    date: I18n.l(edition.scheduled_publication, format: :long_ordinal),
  ).squish
  assert_text I18n.t("edition.confirmation_page.scheduled.detail")

  expect(page).to have_link(
    "View content block",
    href: document_path(
      edition.document,
    ),
  )
end

Then("I should be taken back to the document page") do
  expect(page.current_url).to match(document_path(
                                      Edition.last.document,
                                    ))
end

Then("I am taken back to Content Block Manager home page") do
  assert_equal current_path, root_path
end

And("no draft Content Block Edition has been created") do
  assert_equal 0, Edition.where(state: "draft").count
end

And("no draft Content Block Document has been created") do
  assert_equal 0, Document.count
end

Then("I should see the details for all documents") do
  assert_text "Content Block Manager"

  Document.find_each do |document|
    should_show_summary_title_for_generic_content_block(
      document.title,
    )
  end
end

Then("I should see the details for all documents from {string}") do |organisation_name|
  organisation = Organisation.all.find { |org| org.name == organisation_name }
  Document.with_lead_organisation(organisation.id).each do |document|
    should_show_summary_title_for_generic_content_block(
      document.title,
    )
  end
end

Then("I should see the content block with title {string} returned") do |title|
  expect(page).to have_selector(".govuk-summary-card__title", text: title)
end

Then("I should not see the content block with title {string} returned") do |title|
  expect(page).to_not have_selector(".govuk-summary-card__title", text: title)
end

When("I click to view the document") do
  @schema = @schemas[@content_block.document.block_type]
  click_link href: document_path(@content_block.document)
end

When("I click to view the document with title {string}") do |title|
  content_block = Edition.where(title:).first

  click_link href: document_path(content_block.document)
end

Then("I should see the details for the contact content block") do
  expect(page).to have_selector("h1", text: @content_block.document.title)
  should_show_generic_content_block_details(@content_block.document.title, "contact", @organisation)
end

When("I click the first edit link") do
  click_link "Edit", match: :first
end

When("I click to edit the {string}") do |block_type|
  @action = "update"
  click_link "Edit #{block_type}", match: :first
end

When("I fill out the form") do
  change_details(object_type: @content_block.document.block_type)
end

When("I set all fields to blank") do
  fill_in "Title", with: ""
  fill_in "Description", with: ""
  select "", from: "edition[lead_organisation_id]"
  click_save_and_continue
end

Then("the edition should have been updated successfully") do
  block_type = @content_block.document.block_type

  case block_type
  when "pension"
    should_show_summary_card_for_pension_content_block(
      "Changed title",
      "New description",
      @organisation,
      "new context information",
    )
  else
    should_show_summary_card_for_contact_content_block(
      "Changed title",
      "changed@example.com",
      @organisation,
      "new context information",
    )
  end

  # TODO: this can be removed once the summary list is referring to the Edition's title, not the Document title
  edition = Edition.all.last
  assert_equal "Changed title", edition.title
end

Then("I am asked to review my answers") do
  assert_text "Review contact"
end

Then("I am asked to review my answers for a {string}") do |block_type|
  assert_text "Review #{block_type}"
end

Then("I confirm my answers are correct") do
  check "is_confirmed"
end

When("I review and confirm my answers are correct") do
  review_and_confirm
end

When("I submit without confirming my details") do
  submit
end

When(/^I save and continue$/) do
  click_save_and_continue
end

Then(/^I choose to publish the change now$/) do
  @is_scheduled = false
  publish_now
end

When("I make the changes") do
  change_details
  click_save_and_continue
end

When("I am updating a content block") do
  update_content_block
  add_internal_note
  add_change_note
end

When("one of the content blocks was updated 2 days ago") do
  document = Document.all.last
  document.latest_edition.updated_at = 2.days.before(Time.zone.now)
  document.latest_edition.save!
end

Then("the published state of the object should be shown") do
  visit document_path(@content_block.document)
  expect(page).to have_selector(".govuk-summary-list__key", text: "Status")
  expect(page).to have_selector(".govuk-summary-list__value", text: "Published")
end

Then("I should see the scheduled date on the object") do
  expect(page).to have_selector(".govuk-summary-list__key", text: "Status")
  expect(page).to have_selector(".govuk-summary-list__value", text: @future_date.to_fs(:long_ordinal_with_at).squish)
end

When("I continue after reviewing the links") do
  click_save_and_continue
end

When(/^I add a change note$/) do
  add_change_note
end

Then(/^I should see the object store's title in the header$/) do
  expect(page).to have_selector(".govuk-header__product-name", text: "Content Block Manager")
end

Then(/^I should see the object store's home page title$/) do
  expect(page).to have_title "Home - GOV.UK Content Block Manager"
end

And(/^I should see the object store's navigation$/) do
  expect(page).to have_selector("a.govuk-service-navigation__link[href='#{root_path}']", text: "Blocks")
end

And("I should see the object store's phase banner") do
  expect(page).to have_selector(".govuk-tag", text: "Beta")
  expect(page).to have_link("feedback-content-modelling@digital.cabinet-office.gov.uk", href: "mailto:feedback-content-modelling@digital.cabinet-office.gov.uk")
end

Then(/^I should still see the live edition on the homepage$/) do
  within(".govuk-summary-card", text: @content_block.document.title) do
    @content_block.details.keys.each do |key|
      expect(page).to have_content(@content_block.details[key])
    end
  end
end

Then(/^I should not see the draft document$/) do
  expect(page).not_to have_content(@title)
end

Then("I should see the content block manager home page") do
  expect(page).to have_content("Content Block Manager")
end

When(/^I add an internal note$/) do
  add_internal_note
end

Then(/^I should see a notification that a draft is in progress$/) do
  expect(page).to have_content("There’s a saved draft of this content block")
end

Then(/^I should not see a notification that a draft is in progress$/) do
  expect(page).to_not have_content("There’s a saved draft of this content block")
end

Then("there should be no draft editions remaining") do
  expect(@content_block.document.reload.editions.select { |e| e.state == "draft" }.count).to eq(0)
end

When(/^I click on the link to continue editing$/) do
  click_on "Continue editing"
end

And(/^I update the content block and publish$/) do
  change_details
  click_save_and_continue
  add_internal_note
  add_change_note
  publish_now
  review_and_confirm
end

And(/^I click the back link$/) do
  click_on "Back"
end

Given(/^my pension content block has no rates$/) do
  @content_block.details["rates"] = {}
  @content_block.save!
end

When("I choose {string} from the type dropdown") do |type|
  select type, from: "edition_details_telephones_telephone_numbers_0_type"
end

Then("the label should be set to {string}") do |label|
  expect(find("#edition_details_telephones_telephone_numbers_0_label").value).to eq(label)
end

And(/^I click save$/) do
  click_button "Save"
end

When("the block {string} has been updated") do |title|
  document = Edition.find_by(title:).document
  document.latest_edition.updated_at = Time.zone.now
  document.latest_edition.save!
end

When("the block {string} has testing_artefact set to true") do |title|
  document = Edition.find_by(title:).document
  document.testing_artefact = true
  document.save!
end

Then("the block {string} should appear as the first item in the list") do |title|
  expect(find("div[data-testid='homepage-item-0']")).to have_content(title)
end

Then("I should see a title for the create flow") do
  within("h1") do
    assert_text I18n.t("edition.create.title", block_type: @schema.name.downcase)
  end
end
