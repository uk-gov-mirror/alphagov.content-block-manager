RSpec.describe V2::Document::Show::LegacyActionsComponent, type: :component do
  let(:document) { FactoryBot.build(:v2_document, id: 456) }
  let(:edition) { FactoryBot.build(:v2_time_period_edition, document: document, id: 123, state: state) }

  before do
    allow(document).to receive(:most_recent_edition).and_return(edition)
  end

  describe "button to create new draft edition" do
    context "for 'in-progress' states" do
      V2::Edition.in_progress_states.each do |state|
        context "when the edition is in the '#{state}' state" do
          let(:state) { state }

          before do
            component = described_class.new(document: document)
            render_inline component
          end

          it "does NOT offer an 'Edit {block type}' button to create a new draft edition" do
            expect(page).not_to have_css(
              ".actions a.govuk-button[href='new edition for document - not implemented']",
              text: I18n.t("v2.document.show.buttons.new_edition", block_type: "time period"),
            )
          end
        end
      end
    end

    context "for 'finalised' states" do
      V2::Edition.finalised_states.each do |state|
        context "when the edition is in the '#{state}' state" do
          let(:state) { state }

          context "when there is no more recent draft edition" do
            before do
              component = described_class.new(document: document)
              render_inline component
            end

            it "offers an 'Edit {block type}' button to create a new draft edition" do
              expect(page).to have_css(
                ".actions a.govuk-button[href='new edition for document - not implemented']",
                text: I18n.t("v2.document.show.buttons.new_edition", block_type: "time period"),
              )
            end

            it "does not offers an 'Edit latest edition' button to create a new draft edition" do
              expect(page).not_to have_css(
                ".actions a.govuk-button[href='edit latest edition - not implemented']",
                text: I18n.t("v2.document.show.buttons.latest_edition"),
              )
            end
          end

          context "when there is a more recent draft edition" do
            before do
              component = described_class.new(document: document)
              allow(component).to receive(:has_more_recent_draft?).and_return(true)
              render_inline component
            end

            it "offers an 'Edit latest edition' button to create a new draft edition" do
              expect(page).to have_css(
                ".actions a.govuk-button[href='edit latest edition - not implemented']",
                text: I18n.t("v2.document.show.buttons.latest_edition"),
              )
            end

            it "does not offers an 'Edit {block type}' button to create a new draft edition" do
              expect(page).not_to have_css(
                ".actions a.govuk-button[href='new edition for document - not implemented']",
                text: I18n.t("v2.document.show.buttons.new_edition", block_type: "time period"),
              )
            end
          end
        end
      end
    end
  end

  describe "button to 'Edit draft'" do
    context "for 'in-progress' states other than draft" do
      (V2::Edition.in_progress_states - [:draft]).each do |state|
        context "when the edition is in the '#{state}' state" do
          let(:state) { state }

          before do
            component = described_class.new(document: document)
            render_inline component
          end

          it "offers a secondary 'Edit draft' button to edit the current draft" do
            expect(page).to have_css(
              ".actions a.govuk-button--secondary[href='/v2/documents/456/editions/123/edit']",
              text: I18n.t("v2.document.show.buttons.finalised_not_in_draft"),
            )
          end
        end
      end
    end

    context "when the edition is in the 'draft' state" do
      let(:state) { :draft }

      before do
        component = described_class.new(document: document)
        render_inline component
      end

      it "offers a 'Complete draft' button to edit the current draft" do
        expect(page).to have_css(
          ".actions a.govuk-button[href='/v2/documents/456/editions/123/edit']",
          text: I18n.t("v2.document.show.buttons.finalised_in_draft"),
        )
      end
    end

    context "for 'finalised' states" do
      V2::Edition.finalised_states.each do |state|
        context "when the edition is in the '#{state}' state" do
          let(:state) { state }

          before do
            component = described_class.new(document: document)
            render_inline component
          end

          it "does not offer any button to edit a current draft" do
            expect(page).to have_no_css(
              ".actions a.govuk-button[href='/editions/123/workflow/edit_draft']",
            )
          end
        end
      end
    end
  end

  describe "link to 'Go to published edition" do
    context "when the edition is in the 'published' state" do
      let(:state) { :published }

      before do
        component = described_class.new(document: document)
        render_inline component
      end

      it "does not offer the link to the published edition" do
        expect(page).to have_no_link(I18n.t("v2.document.show.links.published_edition"))
      end
    end

    (V2::Edition.available_states - [:published]).each do |state|
      context "when the edition is in the '#{state}' state" do
        let(:state) { state }

        context "if a published edition exists" do
          before do
            allow(document).to receive(:has_published_edition?).and_return(true)
            component = described_class.new(document: document)
            render_inline component
          end

          it "offers the link to the published edition" do
            expect(page).to have_link(
              I18n.t("v2.document.show.links.published_edition"),
              href: "go to published edition - not implemented",
            )
          end
        end

        context "if a published edition does NOT exist" do
          before do
            allow(document).to receive(:has_published_edition?).and_return(false)
            component = described_class.new(document: document)
            render_inline component
          end

          it "does not offer a link to the published edition" do
            expect(page).to have_no_link(I18n.t("v2.document.show.links.published_edition"))
          end
        end
      end
    end
  end

  describe "link to 'Return to latest edition'" do
    context "when the edition being viewed is published" do
      let(:state) { :published }

      context "and the edition being viewed is not the latest edition" do
        before do
          component = described_class.new(document: document)
          allow(component).to receive(:has_more_recent_draft?).and_return(true)
          render_inline component
        end

        it "shows the link to return to the latest edition" do
          expect(page).to have_link(I18n.t("v2.document.show.links.newer_draft_edition", href: "return to most recent edition - not implemented"))
        end
      end

      context "and the edition being viewed is the latest edition" do
        before do
          component = described_class.new(document: document)
          render_inline component
        end

        it "does not show the link to return to the latest edition" do
          expect(page).to have_no_link(I18n.t("v2.document.show.links.newer_draft_edition", href: "return to most recent edition - not implemented"))
        end
      end
    end

    (V2::Edition.available_states - [:published]).each do |state|
      context "when the edition being viewed is not published (#{state})" do
        let(:state) { state }

        before do
          component = described_class.new(document: document)
          render_inline component
        end

        it "does not show the link to return to the latest edition" do
          expect(page).to have_no_link(I18n.t("v2.document.show.links.newer_draft_edition"))
        end
      end
    end
  end
end
