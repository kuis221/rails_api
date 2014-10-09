require 'rails_helper'

describe 'routes for areas', type: :routing do
  it 'routes to #index' do
    expect(get: '/areas').to route_to('areas#index')
  end

  it 'routes to #new' do
    expect(get: '/areas/new').to route_to('areas#new')
  end

  it 'routes to #show' do
    expect(get: '/areas/1').to route_to('areas#show', id: '1')
  end

  it 'routes to #edit' do
    expect(get: '/areas/1/edit').to route_to('areas#edit', id: '1')
  end

  it 'routes to #create' do
    expect(post: '/areas').to route_to('areas#create')
  end

  it 'routes to #update' do
    expect(put: '/areas/1').to route_to('areas#update', id: '1')
  end

  it 'routes to #autocomplete' do
    expect(get: '/areas/autocomplete').to route_to('areas#autocomplete')
  end

  it 'routes to #filters' do
    expect(get: '/areas/filters').to route_to('areas#filters')
  end

  it 'routes to #items' do
    expect(get: '/areas/items').to route_to('areas#items')
  end

  it "doesn't routes to #destroy" do
    expect(delete: '/areas/1').not_to be_routable
  end

  it 'routes to #cities' do
    expect(get: '/areas/1/cities').to route_to('areas#cities', id: '1')
  end

  describe 'nested inside a place' do
    it 'routes to #new' do
      expect(get: '/places/1/areas/new').to route_to('areas#new', place_id: '1')
    end
    it 'routes to #create' do
      expect(post: '/places/1/areas').to route_to('areas#create', place_id: '1')
    end
    it "doesn't routes to #destroy" do
      expect(delete: '/places/1/areas/areas/1').not_to be_routable
    end

    it "doesn't routes to #index" do
      expect(get: '/places/1/areas').not_to be_routable
    end

    it "doesn't routes to #show" do
      expect(get: '/places/1/areas/1').not_to be_routable
    end

    it "doesn't routes to #edit" do
      expect(get: '/places/1/areas/1/edit').not_to be_routable
    end

    it "doesn't routes to #update" do
      expect(put: '/places/1/areas/1').not_to be_routable
    end
  end
end
