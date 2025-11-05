Then("I should see the status of the latest edition of the block") do
  edition = @content_block.document.editions.last
  should_show_the_status_for(edition: edition)
end

def should_show_the_status_for(edition:)
  translated_state = I18n.t("edition.states.label.#{edition.state}")

  within ".govuk-tag[title='Status: #{translated_state}']" do
    expect(page).to have_content(translated_state)
  end
end
