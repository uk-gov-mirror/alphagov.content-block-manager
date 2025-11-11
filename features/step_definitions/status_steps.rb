Then("I should see the status of the latest edition of the block") do
  edition = @content_block.document.editions.last
  should_show_the_status_for(edition: edition)
end

def should_show_the_status_for(edition:)
  should_see_status_for(state: edition.state)
end

Then(/I see that the edition is in ([^"]*) state/) do |state|
  should_see_status_for(state: state)
end

def should_see_status_for(state:)
  translated_state = I18n.t("edition.states.label.#{state}")

  within ".govuk-tag[title='Status: #{translated_state}']" do
    expect(page).to have_content(translated_state)
  end
end
