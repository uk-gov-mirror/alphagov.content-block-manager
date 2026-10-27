When("I am viewing the pre publication review page") do
  visit new_v2_document_edition_pre_publication_review_path(@time_period_edition.document, @time_period_edition)
end

When("I confirm that the block details are correct and continue") do
  check I18n.t("v2.edition.pre_publication_review.confirm")
  click_on "Create"
end

When("I follow the link to edit the date range") do
  within(".govuk-summary-card", text: "Date range details") do
    click_link("Edit")
  end
end

When("I follow the link to edit the time period details") do
  within(".govuk-summary-card", text: "Time period details") do
    click_link("Edit")
  end
end

And("I see a notice that the update was successful") do
  within(".govuk-notification-banner--success") do
    expect(page).to have_content(I18n.t("v2.time_period_edition.update.success"))
  end
end
