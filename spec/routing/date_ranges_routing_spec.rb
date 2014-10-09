require 'rails_helper'

describe 'routes for date ranges', type: :routing do
  it 'routes to #index' do
    expect(get: '/date_ranges').to route_to('date_ranges#index')
  end

  it 'routes to #new' do
    expect(get: '/date_ranges/new').to route_to('date_ranges#new')
  end

  it 'routes to #show' do
    expect(get: '/date_ranges/1').to route_to('date_ranges#show', id: '1')
  end

  it 'routes to #edit' do
    expect(get: '/date_ranges/1/edit').to route_to('date_ranges#edit', id: '1')
  end

  it 'routes to #create' do
    expect(post: '/date_ranges').to route_to('date_ranges#create')
  end

  it 'routes to #update' do
    expect(put: '/date_ranges/1').to route_to('date_ranges#update', id: '1')
  end

  it 'routes to #autocomplete' do
    expect(get: '/events/autocomplete').to route_to('events#autocomplete')
  end

  it 'routes to #filters' do
    expect(get: '/events/filters').to route_to('events#filters')
  end

  it 'routes to #items' do
    expect(get: '/events/items').to route_to('events#items')
  end

  it "doesn't routes to #destroy" do
    expect(delete: '/date_ranges/1').not_to be_routable
  end

end
