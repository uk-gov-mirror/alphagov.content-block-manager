When("I follow the workflow steps through to the final review step") do
  create_new_edition
  complete_note_step
  complete_change_note_step
  complete_scheduling_step
  expect(page).to have_content("Review pension")
end

Then("I see a principal call to action of 'Send to 2i'") do
  within("form[action='#{edition_status_transitions_path(edition)}']")
  expect(page).to have_button("Send to 2i")
end

Then("I see a secondary call to action of 'Edit pension'") do
  expect(page).to have_css(
    "a.govuk-button--secondary[href='#{new_document_edition_path(edition.document)}']",
    text: "Edit pension",
  )
end

When("I opt to send the edition to 2i") do
  click_button "Send to 2i"
end

def create_new_edition
  click_link("Edit pension")
  expect(page).to have_content("Edit pension")
  click_button("Save and continue")
end

def complete_note_step
  expect(page).to have_content("Create internal note")
  click_button("Save and continue")
end

def complete_change_note_step
  expect(page).to have_content("Do users have to know the content has changed?")
  choose("No - it's a minor edit that does not change the meaning")
  click_button("Save and continue")
end

def complete_scheduling_step
  expect(page).to have_content("Select publish date")
  choose("Publish the edit now")
  click_button("Save and continue")
end

def edition
  @edition ||= Edition.last
end
