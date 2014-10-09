require 'rails_helper'

describe 'routes for brands', type: :routing do
  describe 'nested to campaigns' do
    it 'routes to #index' do
      expect(get: '/campaigns/:campaign_id/brands').to route_to('brands#index', campaign_id: ':campaign_id')
    end
  end

  describe 'nested to brand portfolios' do
    it 'routes to #new' do
      expect(get: '/brand_portfolios/:brand_portfolio_id/brands/new').to route_to('brands#new', brand_portfolio_id: ':brand_portfolio_id')
    end
    it 'routes to #create' do
      expect(post: '/brand_portfolios/:brand_portfolio_id/brands').to route_to('brands#create', brand_portfolio_id: ':brand_portfolio_id')
    end
  end

  describe 'not nested' do
    it 'routes to #index' do
      expect(get: '/brands').to route_to('brands#index')
    end

    it 'routes to #new' do
      expect(get: '/brands/new').to route_to('brands#new')
    end

    it 'routes to #show' do
      expect(get: '/brands/1').to route_to('brands#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/brands/1/edit').to route_to('brands#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/brands').to route_to('brands#create')
    end

    it 'routes to #update' do
      expect(put: '/brands/1').to route_to('brands#update', id: '1')
    end

    it "doesn't routes to #destroy" do
      expect(delete: '/brands/1').not_to be_routable
    end

    it 'routes to #autocomplete' do
      expect(get: '/brands/autocomplete').to route_to('brands#autocomplete')
    end

    it 'routes to #filters' do
      expect(get: '/brands/filters').to route_to('brands#filters')
    end

    it 'routes to #items' do
      expect(get: '/brands/items').to route_to('brands#items')
    end
  end
end
