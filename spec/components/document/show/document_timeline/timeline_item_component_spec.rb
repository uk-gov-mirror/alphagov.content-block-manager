RSpec.describe Document::Show::DocumentTimeline::TimelineItemComponent, type: :component do
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::UrlHelper
  include ApplicationHelper

  let(:user) { create(:user) }
  let(:schema) { double(:schema, subschemas: []) }

  let(:fact_check_skipped) { nil }

  let(:edition) do
    build(:edition,
          :pension,
          change_note: nil,
          internal_change_note: nil,
          review_outcome: ReviewOutcome.new,
          fact_check_outcome: FactCheckOutcome.new(skipped: fact_check_skipped))
  end

  let(:version) do
    build(
      :content_block_version,
      event: "created",
      whodunnit: user.id,
      state: "published",
      created_at: 4.days.ago,
      item: edition,
    )
  end

  let(:domain_event) { build(:domain_event, edition:, user:, version:, created_at: version.created_at) }

  let(:is_latest) { false }
  let(:is_first_published_version) { false }

  let(:table_stub) { double("table_component") }

  let(:component) do
    described_class.new(
      domain_event:,
      schema:,
      is_first_published_version:,
      is_latest:,
    )
  end

  describe "when not the latest or first published" do
    before do
      render_inline component
    end

    it "renders a timeline item component" do
      expect(page).to have_css ".timeline__title", text: "Published"
      page.find ".timeline__byline" do |byline|
        assert_includes byline.native.to_s, "by #{linked_author(user, { class: 'govuk-link' })}"
      end
      expect(page).to have_css "time[datetime='#{version.created_at.iso8601}']", text: version.created_at.to_fs(:long_ordinal_with_at)
    end

    it "does not show the latest tag" do
      expect(page).to_not have_css ".timeline__latest", text: "Latest"
    end

    it "does not show the table component" do
      expect(page).to_not have_css ".timeline__diff-table"
    end
  end

  describe "when the version is the first published version" do
    let(:is_latest) { false }
    let(:is_first_published_version) { true }

    before do
      render_inline component
    end

    it "returns a created title" do
      expect(page).to have_css(
        ".timeline__title",
        text: I18n.t("timeline_item.title.published", block_type: "Pension"),
      )
    end

    context "and its edition indicates that the review was performed" do
      let(:fact_check_skipped) { false }

      it "shows the review outcome" do
        expect(page).to have_css(".timeline__review-outcome") do
          expect(page).to have_content("Fact check performed")
        end
      end
    end

    context "and its edition indicates that the review was skipped" do
      let(:fact_check_skipped) { true }

      it "shows the review outcome" do
        expect(page).to have_css(".timeline__review-outcome") do
          expect(page).to have_content("Fact check skipped")
        end
      end
    end
  end

  describe "when the version is the latest version" do
    let(:is_latest) { true }
    let(:is_first_published_version) { false }

    before do
      render_inline component
    end

    it "shows the latest tag" do
      expect(page).to have_css ".timeline__latest", text: "Latest"
    end
  end

  describe "when external changenotes are present" do
    let(:edition) { build(:edition, :pension, change_note: "changed a to b", internal_change_note: nil) }

    before do
      render_inline component
    end

    it "shows the change note" do
      expect(page).to have_css ".timeline__note--public p", text: "changed a to b"
    end
  end

  describe "when internal changenotes are present" do
    let(:edition) { build(:edition, :pension, change_note: nil, internal_change_note: "changed x to y") }

    before do
      render_inline component
    end

    it "shows the change note" do
      expect(page).to have_css ".timeline__note--internal p", text: "changed x to y"
    end
  end

  describe "when field diffs are present" do
    let(:field_diffs) { { "foo" => DiffItem.new(previous_value: "previous value", new_value: "new value") } }
    let(:version) do
      build_stubbed(
        :content_block_version,
        event: "created",
        whodunnit: user.id,
        state: "published",
        created_at: 4.days.ago,
        item: edition,
        field_diffs:,
      )
    end

    let!(:table_component) do
      Document::Show::DocumentTimeline::FieldChangesTableComponent.new(
        version:,
        schema:,
      )
    end

    before do
      expect(Document::Show::DocumentTimeline::FieldChangesTableComponent)
        .to receive(:new)
        .with(version:, schema:)
        .and_return(table_component)

      expect(component)
        .to receive(:render)
        .with(table_component)
        .once
        .and_return("TABLE COMPONENT")
    end

    it "renders the table component unopened" do
      expect(component).to receive(:render)
                             .with("govuk_publishing_components/components/details", { title: "Details of changes", open: false, summary_aria_attributes: { label: "Details of changes - Published" } })

      render_inline component
    end

    describe "when the version is the latest version" do
      let(:is_latest) { true }

      it "renders the details as open" do
        expect(component)
          .to receive(:render)
          .with("govuk_publishing_components/components/details", { title: "Details of changes", open: true, summary_aria_attributes: { label: "Details of changes - Published" } })

        render_inline component
      end
    end
  end

  describe "when there are embedded objects" do
    describe "with a 1:N relationship (e.g. Contact addresses)" do
      let(:relationship_type) { double(:relationship_type, one_to_one?: false) }
      let(:addresses_subschema) { double(:subschema, id: "addresses", relationship_type:) }
      let(:schema) { double(:schema, subschemas: [addresses_subschema], fields: []) }

      let(:edition) do
        build(:edition,
              :contact,
              details: {
                "addresses" => {
                  "home-address" => { "title" => "Home Address", "street" => "123 Main St" },
                },
              },
              change_note: nil,
              internal_change_note: nil,
              review_outcome: ReviewOutcome.new,
              fact_check_outcome: FactCheckOutcome.new)
      end

      describe "when there are field diffs" do
        let(:field_diffs) do
          {
            "details" => {
              "addresses" => {
                "home-address" => {
                  "street" => DiffItem.new(previous_value: "100 Old Road", new_value: "123 Main St"),
                },
              },
            },
          }
        end

        let(:version) do
          build_stubbed(
            :content_block_version,
            event: "created",
            whodunnit: user.id,
            state: "published",
            created_at: 4.days.ago,
            item: edition,
            field_diffs:,
          )
        end

        it "renders a table for each changed object, using the object's title as caption" do
          render_inline component

          expect(page).to have_css("caption", text: "Home Address", visible: :all)

          expect(page).to have_css("th", text: "Street", visible: :all)
          expect(page).to have_css("td", text: "100 Old Road", visible: :all)
          expect(page).to have_css("td", text: "123 Main St", visible: :all)
        end

        it "does not render tables for unchanged embedded objects" do
          render_inline component

          expect(page).to have_css("caption", count: 1, visible: :all)
        end
      end
    end

    describe "with a 1:1 relationship (e.g. TimePeriod date_range)" do
      let(:relationship_type) { double(:relationship_type, one_to_one?: true) }
      let(:date_range_subschema) { double(:subschema, id: "date_range", relationship_type:) }
      let(:schema) { double(:schema, subschemas: [date_range_subschema], fields: []) }

      let(:edition) do
        build(:edition,
              :time_period,
              details: {
                "date_range" => {
                  "start" => "2025-02-01T09:00:00+00:00",
                  "end" => "2025-12-31T18:00:00+00:00",
                },
              },
              change_note: nil,
              internal_change_note: nil,
              review_outcome: ReviewOutcome.new,
              fact_check_outcome: FactCheckOutcome.new)
      end

      describe "when there are field diffs" do
        let(:field_diffs) do
          {
            "details" => {
              "date_range" => {
                "start" => DiffItem.new(
                  previous_value: "2025-01-01T09:00:00+00:00",
                  new_value: "2025-02-01T09:00:00+00:00",
                ),
                "end" => DiffItem.new(
                  previous_value: "2025-12-31T17:00:00+00:00",
                  new_value: "2025-12-31T18:00:00+00:00",
                ),
              },
            },
          }
        end

        let(:version) do
          build_stubbed(
            :content_block_version,
            event: "created",
            whodunnit: user.id,
            state: "published",
            created_at: 4.days.ago,
            item: edition,
            field_diffs:,
          )
        end

        it "renders a single table with subschema id as caption (humanized)" do
          render_inline component

          expect(page).to have_css("caption", text: "Date range", visible: :all)
        end

        it "renders rows for each changed field with previous and new values" do
          render_inline component

          expect(page).to have_css("th", text: "Start", visible: :all)
          expect(page).to have_css("td", text: "2025-01-01T09:00:00+00:00", visible: :all)
          expect(page).to have_css("td", text: "2025-02-01T09:00:00+00:00", visible: :all)

          expect(page).to have_css("th", text: "End", visible: :all)
          expect(page).to have_css("td", text: "2025-12-31T17:00:00+00:00", visible: :all)
          expect(page).to have_css("td", text: "2025-12-31T18:00:00+00:00", visible: :all)
        end

        it "does not render multiple tables for the same 1:1 object" do
          render_inline component

          expect(page).to have_css("caption", text: "Date range", count: 1, visible: :all)
        end
      end
    end

    describe "when there are no field diffs for the embedded object" do
      let(:relationship_type) { double(:relationship_type, one_to_one?: false) }
      let(:subschema1) { double(:subschema, id: "embedded_schema", relationship_type:) }
      let(:subschema2) { double(:subschema, id: "other_embedded_schema", relationship_type:) }
      let(:schema) { double(:schema, subschemas: [subschema1, subschema2], fields: %w[description]) }
      let(:field_diffs) do
        {
          "details" => {
            "description" => DiffItem.new(previous_value: "old description", new_value: "new description"),
          },
        }
      end

      let(:version) do
        build_stubbed(
          :content_block_version,
          event: "created",
          whodunnit: user.id,
          state: "published",
          created_at: 4.days.ago,
          item: edition,
          field_diffs:,
        )
      end

      it "renders only the main object field changes, not embedded object tables" do
        render_inline component

        expect(page).to have_css("th", text: "Description", visible: :all)
        expect(page).to have_css("td", text: "old description", visible: :all)
        expect(page).to have_css("td", text: "new description", visible: :all)

        expect(page).not_to have_css("caption", text: "Embedded schema", visible: :all)
        expect(page).not_to have_css("caption", text: "Other embedded schema", visible: :all)
      end
    end
  end

  context "when version has the 'awaiting_review' state" do
    before do
      version.state = "awaiting_review"
      render_inline component
    end

    it "sets the #title to be 'Sent to review" do
      expect(page).to have_css(".timeline__title") do
        expect(page).to have_content(I18n.t("timeline_item.title.awaiting_review"))
      end
    end
  end

  context "when version has the 'draft_complete' state" do
    before do
      version.state = "draft_complete"
    end

    it "sets the #title to be 'Draft completed'" do
      render_inline component

      expect(page).to have_css(".timeline__title") do
        expect(page).to have_content(I18n.t("timeline_item.title.draft_complete"))
      end
    end
  end

  context "when version has the 'awaiting_factcheck' state" do
    before do
      version.state = "awaiting_factcheck"
    end

    it "sets the #title to be 'Sent to fact check'" do
      render_inline component

      expect(page).to have_css(".timeline__title") do
        expect(page).to have_content(I18n.t("timeline_item.title.awaiting_factcheck"))
      end
    end

    context "and its edition indicates that the review was performed" do
      before do
        edition.review_outcome.skipped = false
      end

      it "shows the review outcome" do
        render_inline component

        expect(page).to have_css(".timeline__review-outcome") do
          expect(page).to have_content("2i review performed")
        end
      end
    end

    context "and its edition indicates that the review was skipped" do
      before do
        edition.review_outcome.skipped = true
      end

      it "shows the review outcome" do
        render_inline component

        expect(page).to have_css(".timeline__review-outcome") do
          expect(page).to have_content("2i review skipped")
        end
      end
    end
  end

  describe "when the version has an outcome" do
    context "and the outcome has a performer" do
      let(:user) { build(:user, name: "Dave", email: "dave@example.com") }
      let(:review_outcome) { ReviewOutcome.new.tap { |o| o.performer = user.name } }
      let(:fact_check_outcome) { FactCheckOutcome.new.tap { |o| o.performer = user.email } }
      let(:edition) { build(:edition, review_outcome: review_outcome, fact_check_outcome: fact_check_outcome) }

      context "and the version is in the 'awaiting_factcheck' state" do
        before { version.state = "awaiting_factcheck" }

        it "should show the Review outcome performer" do
          render_inline component

          expect(page).to have_css(".timeline__review-outcome .govuk-body") do |element|
            expect(element).to have_content("2i review performed by Dave")
          end
        end
      end

      context "and the version is in the 'published' state" do
        before { version.state = "published" }

        it "should show the fact check outcome performer" do
          render_inline component

          expect(page).to have_css(".timeline__review-outcome .govuk-body") do |element|
            expect(element).to have_content("Fact check performed by dave@example.com", exact: true)
          end
        end
      end
    end

    context "and the outcome **does not** have a performer" do
      let(:review_outcome) { ReviewOutcome.new }
      let(:fact_check_outcome) { FactCheckOutcome.new }
      let(:edition) { build(:edition, review_outcome: review_outcome, fact_check_outcome: fact_check_outcome) }

      context "and the version is in the 'awaiting_factcheck' state" do
        before { version.state = "awaiting_factcheck" }

        it "should show the Review outcome performer" do
          render_inline component

          expect(page).to have_css(".timeline__review-outcome .govuk-body") do |element|
            expect(element).to have_content("2i review performed", exact: true)
          end
        end
      end

      context "and the version is in the 'published' state" do
        before { version.state = "published" }

        it "should not show the fact check outcome performer" do
          render_inline component

          expect(page).to have_css(".timeline__review-outcome .govuk-body") do |element|
            expect(element).to have_text("Fact check performed", exact: true)
          end
        end
      end
    end
  end

  describe "when the version **does not** have an outcome" do
    let(:edition) { build(:edition, review_outcome: nil, fact_check_outcome: nil) }

    context "and the version is in the 'awaiting_factcheck' state" do
      before { version.state = "awaiting_factcheck" }

      it "should not show any outcome" do
        render_inline component

        expect(page).not_to have_css(".timeline__review-outcome")
      end
    end

    context "and the version is in the 'published' state" do
      before { version.state = "published" }

      it "should not show any outcome" do
        render_inline component

        expect(page).not_to have_css(".timeline__review-outcome")
      end
    end
  end

  context "when the version is in the 'scheduled' state" do
    before do
      version.state = "scheduled"
    end

    context "when scheduled_publication is present in DomainEvent" do
      before do
        edition.scheduled_publication = nil
        allow_any_instance_of(DomainEvent).to receive(:metadata).and_return({ "scheduled_publication" => Time.zone.parse("2026-01-01 13:05").to_fs(:long_ordinal_with_at) })
      end

      it "sets the #title to be 'Scheduled for publishing {string}'" do
        render_inline component

        expect(page).to have_css(".timeline__title") do
          expect(page).to have_content(
            I18n.t("timeline_item.title.scheduled", datetime_string: "on 1 January 2026 at 1:05pm"),
          )
        end
      end
    end

    context "when scheduled_publication is present in the Edition" do
      before do
        edition.scheduled_publication = Time.zone.parse("2026-01-01 13:05")
      end

      it "sets the #title to be 'Scheduled for publishing {string}'" do
        render_inline component

        expect(page).to have_css(".timeline__title") do
          expect(page).to have_content(
            I18n.t("timeline_item.title.scheduled", datetime_string: "on 1 January 2026 at 1:05pm"),
          )
        end
      end
    end

    context "when scheduled_publication is not present" do
      before do
        edition.scheduled_publication = nil
        edition.scheduled_publication = nil
        allow_any_instance_of(DomainEvent).to receive(:metadata).and_return({})
      end

      it "sets the #title to be 'Scheduled for publishing'" do
        render_inline component

        expect(page).to have_css(".timeline__title") do
          expect(page).to have_content(
            I18n.t("timeline_item.title.scheduled", datetime_string: nil),
          )
        end
      end
    end
  end

  context "when the domain event does not have a version" do
    let(:version) { nil }
    let(:domain_event) do
      build(:domain_event,
            edition:,
            name: "edition.review.performed",
            user:,
            version:,
            created_at: 4.days.ago)
    end

    it "should not throw an error" do
      expect { render_inline component }.not_to raise_error
    end

    it "should show the title based on the domain event" do
      render_inline component

      expect(page).to have_css(".timeline__title", text: I18n.t("domain_event.title.#{domain_event.name}"))
    end

    context "and the domain event is a review outcome" do
      context "and the review was actually performed" do
        %w[edition.review.performed edition.fact_check.performed].each do |event_name|
          let(:domain_event) do
            build(:domain_event,
                  edition:,
                  name: event_name,
                  user:,
                  version: nil,
                  metadata: { "performer" => "dave" },
                  created_at: 4.days.ago)
          end

          it "should show the review outcome with the performer" do
            render_inline component

            expect(page).to have_css(".timeline__review-outcome .govuk-body") do |element|
              expect(element).to have_content(I18n.t("domain_event.body.#{domain_event.name}", performer: "dave"))
            end
          end
        end
      end

      context "and the review was skipped" do
        %w[edition.review.skipped edition.fact_check.skipped].each do |event_name|
          let(:domain_event) do
            build(:domain_event,
                  edition:,
                  name: event_name,
                  user:,
                  version: nil,
                  created_at: 4.days.ago)
          end

          it "should show the review outcome with no reference to the performer" do
            render_inline component

            expect(page).to have_css(".timeline__review-outcome .govuk-body") do |element|
              expect(element).to have_content(I18n.t("domain_event.body.#{domain_event.name}"))
            end
          end
        end
      end
    end
  end
end
