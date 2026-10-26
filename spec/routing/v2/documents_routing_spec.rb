RSpec.describe "V2 documents routing", type: :routing do
  describe "V2 Documents controller" do
    before do
      FactoryBot.create(:v2_document, id: 1234)
    end

    it "does not create all default POST routes" do
      expect(get: "/v2/documents/new").not_to route_to("v2/documents#new")
      expect(post: "/v2/documents").not_to be_routable
      expect(get: "/v2/documents/1234/edit").not_to be_routable
      expect(put: "/v2/documents/1234").not_to be_routable
      expect(patch: "/v2/documents/1234").not_to be_routable
      expect(delete: "/v2/documents/1234").not_to be_routable
    end

    it "routes '/v2/documents' to 'v2/documents#index'" do
      expect(get: "/v2/documents").to route_to("v2/documents#index")
    end

    it "routes '/v2/documents/:id' to 'v2/documents#show'" do
      expect(get: "/v2/documents/1234").to route_to("v2/documents#show", id: "1234")
    end
  end
end
