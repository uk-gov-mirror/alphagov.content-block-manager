RSpec.describe "V2 time period editions routing", type: :routing do
  before do
    document = FactoryBot.create(:v2_document, id: 1234)
    FactoryBot.create(:v2_time_period_edition, id: 5678, document: document)
  end

  describe "V2 namespace" do
    describe "Nested time period edition routes" do
      describe "V2 Time period editions controller" do
        it "does not create all default POST routes" do
          expect(get: "/v2/documents/1234/editions").not_to be_routable
          expect(get: "/v2/documents/1234/editions/new").not_to be_routable
          expect(post: "/v2/documents/1234/editions").not_to be_routable
          expect(get: "/v2/documents/1234/editions/5678").not_to be_routable
          expect(delete: "/v2/documents/1234/editions/5678").not_to be_routable
        end

        it "routes 'v2/documents/:document_id/editions/:id/edit' to 'v2/time_period_editions#edit'" do
          expect(get: "/v2/documents/1234/editions/5678/edit").to route_to("v2/time_period_editions#edit", document_id: "1234", id: "5678")
        end

        it "routes 'v2/documents/:document_id/editions/:id' to 'v2/time_period_editions#update'" do
          expect(put: "/v2/documents/1234/editions/5678").to route_to("v2/time_period_editions#update", document_id: "1234", id: "5678")
          expect(patch: "/v2/documents/1234/editions/5678").to route_to("v2/time_period_editions#update", document_id: "1234", id: "5678")
        end
      end

      describe "V2 Time period date ranges controller" do
        it "does not create all default POST routes" do
          expect(get: "/v2/documents/1234/editions/5678/date_range").not_to be_routable
          expect(get: "/v2/documents/1234/editions/5678/date_range/new").not_to be_routable
          expect(post: "/v2/documents/1234/editions/5678/date_range").not_to be_routable
          expect(get: "/v2/documents/1234/editions/5678/date_range/910").not_to be_routable
          expect(delete: "/v2/documents/1234/editions/5678/date_range").not_to be_routable
        end

        it "routes 'v2/documents/:document_id/editions/:edition_id/edit/date-range/:id' to 'v2/time_period_date_ranges#edit'" do
          expect(get: "/v2/documents/1234/editions/5678/date-range/edit").to route_to("v2/time_period_date_ranges#edit", document_id: "1234", edition_id: "5678")
        end

        it "routes 'v2/documents/:document_id/editions/:edition_id/date-range/:id' to 'v2/time_period_date_ranges#update'" do
          expect(put: "/v2/documents/1234/editions/5678/date-range").to route_to("v2/time_period_date_ranges#update", document_id: "1234", edition_id: "5678")
          expect(patch: "/v2/documents/1234/editions/5678/date-range").to route_to("v2/time_period_date_ranges#update", document_id: "1234", edition_id: "5678")
        end
      end

      describe "V2 Pre publication review controller" do
        it "routes 'v2/documents/:document_id/editions/:id/pre-publication-reviews/new' to 'v2/pre_publication_reviews#new'" do
          expect(get: "/v2/documents/1234/editions/5678/pre-publication-reviews/new").to route_to("v2/pre_publication_reviews#new", document_id: "1234", edition_id: "5678")
        end

        it "routes 'v2/documents/:document_id/editions/:id/pre-publication-reviews' to 'v2/pre_publication_reviews#create'" do
          expect(post: "/v2/documents/1234/editions/5678/pre-publication-reviews").to route_to("v2/pre_publication_reviews#create", document_id: "1234", edition_id: "5678")
        end
      end
    end

    describe "Un-nested time period edition routes" do
      describe "V2 Time period editions controller" do
        it "does not create all default POST routes" do
          expect(get: "/v2/time_period_editions").not_to be_routable
          expect(get: "/v2/time_period_editions/5678").not_to be_routable
          expect(delete: "/v2/time_period_editions/5678").not_to be_routable
          expect(get: "/v2/time_period_editions/5678/edit").not_to be_routable
          expect(put: "/v2/time_period_editions/5678").not_to be_routable
          expect(patch: "/v2/time_period_editions/5678").not_to be_routable
        end

        it "routes 'v2/time_period_editions/new' to 'v2/time_period_editions#new'" do
          expect(get: "/v2/time_period_editions/new").to route_to("v2/time_period_editions#new")
        end

        it "routes 'v2/time_period_editions' to 'v2/time_period_editions#create'" do
          expect(post: "/v2/time_period_editions").to route_to("v2/time_period_editions#create")
        end
      end
    end
  end
end
