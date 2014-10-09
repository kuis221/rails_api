require 'rails_helper'

describe 'routes for events', type: :routing do
  it 'routes to #index' do
    expect(get: '/events').to route_to('events#index')
  end

  it 'routes to #new' do
    expect(get: '/events/new').to route_to('events#new')
  end

  it 'routes to #show' do
    expect(get: '/events/1').to route_to('events#show', id: '1')
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

  it 'routes to #edit' do
    expect(get: '/events/1/edit').to route_to('events#edit', id: '1')
  end

  it 'routes to #activate' do
    expect(get: '/events/1/activate').to route_to('events#activate', id: '1')
  end

  it 'routes to #deactivate' do
    expect(get: '/events/1/deactivate').to route_to('events#deactivate', id: '1')
  end

  it 'routes to #create' do
    expect(post: '/events').to route_to('events#create')
  end

  it 'routes to #update' do
    expect(put: '/events/1').to route_to('events#update', id: '1')
  end

  it "does't routes to #destroy" do
    expect(delete: '/events/1').not_to be_routable
  end
end
