require "rails_helper"

describe 'routes for document folders', :type => :routing do
  describe 'nested within brand_ambassadors namespace' do
    it "doesn't routes to #index" do
      expect(get: "/brand_ambassadors/folders").not_to be_routable
    end

    it "routes to #new" do
      expect(get: "/brand_ambassadors/folders/new").to route_to("document_folders#new")
    end

    it "doesn't routes to #show" do
      expect(get: "/brand_ambassadors/folders/1").not_to be_routable
    end

    it "doesn't routes to #edit" do
      expect(get: "/brand_ambassadors/folders/1/edit").not_to be_routable
    end

    it "routes to #create" do
      expect(post: "/brand_ambassadors/folders").to route_to("document_folders#create")
    end

    it "doesn't routes to #update" do
      expect(put: "/brand_ambassadors/folders/1").not_to be_routable
    end

    it "doesn't routes to #destroy" do
      expect(delete: "/brand_ambassadors/folders/1").not_to be_routable
    end
  end

  describe 'nested within brand_ambassadors#visits' do
    it "doesn't routes to #index" do
      expect(get: "/brand_ambassadors/folders").not_to be_routable
    end

    it "routes to #new" do
      expect(get: "/brand_ambassadors/visits/1/folders/new").to route_to("document_folders#new", visit_id: '1')
    end

    it "doesn't routes to #show" do
      expect(get: "/brand_ambassadors/visits/1/folders/1").not_to be_routable
    end

    it "doesn't routes to #edit" do
      expect(get: "/brand_ambassadors/visits/1/folders/1/edit").not_to be_routable
    end

    it "routes to #create" do
      expect(post: "/brand_ambassadors/visits/1/folders/").to route_to("document_folders#create", visit_id: '1')
    end

    it "doesn't routes to #update" do
      expect(put: "/brand_ambassadors/visits/1/folders/1").not_to be_routable
    end

    it "doesn't routes to #destroy" do
      expect(delete: "/brand_ambassadors/visits/1/folders/1").not_to be_routable
    end
  end
end
