require 'rails_helper'

describe 'routes for brand portfolios', type: :routing do
  it 'routes to #index' do
    expect(get: '/brand_portfolios').to route_to('brand_portfolios#index')
  end

  it 'routes to #new' do
    expect(get: '/brand_portfolios/new').to route_to('brand_portfolios#new')
  end

  it 'routes to #show' do
    expect(get: '/brand_portfolios/1').to route_to('brand_portfolios#show', id: '1')
  end

  it 'routes to #edit' do
    expect(get: '/brand_portfolios/1/edit').to route_to('brand_portfolios#edit', id: '1')
  end

  it 'routes to #create' do
    expect(post: '/brand_portfolios').to route_to('brand_portfolios#create')
  end

  it 'routes to #update' do
    expect(put: '/brand_portfolios/1').to route_to('brand_portfolios#update', id: '1')
  end

  it 'routes to #autocomplete' do
    expect(get: '/brand_portfolios/autocomplete').to route_to('brand_portfolios#autocomplete')
  end

  it 'routes to #filters' do
    expect(get: '/brand_portfolios/filters').to route_to('brand_portfolios#filters')
  end

  it 'routes to #items' do
    expect(get: '/brand_portfolios/items').to route_to('brand_portfolios#items')
  end

  it "doesn't routes to #destroy" do
    expect(delete: '/brand_portfolios/1').not_to be_routable
  end

  it 'routes to #delete_brand' do
    expect(delete: '/brand_portfolios/1/brands/:brand_id').to route_to('brand_portfolios#delete_brand', id: '1', brand_id: ':brand_id')
  end

  it 'routes to #select_brands' do
    expect(get: '/brand_portfolios/1/brands/select').to route_to('brand_portfolios#select_brands', id: '1')
  end

  it 'routes to #add_brands' do
    expect(post: '/brand_portfolios/1/brands/add').to route_to('brand_portfolios#add_brands', id: '1')
  end

  it 'routes to #brands' do
    expect(get: '/brand_portfolios/:brand_portfolio_id/brands').to route_to('brand_portfolios#brands', id: ':brand_portfolio_id', action: 'brands')
  end

end
