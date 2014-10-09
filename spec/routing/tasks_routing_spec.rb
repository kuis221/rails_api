require 'rails_helper'

describe 'routes for tasks', type: :routing do
  it 'routes to #index' do
    expect(get: '/tasks/mine').to route_to('tasks#index', scope: 'user')
    expect(get: '/tasks/my_teams').to route_to('tasks#index', scope: 'teams')
  end

  it 'routes to #new' do
    expect(get: '/tasks/new').to route_to('tasks#new')
  end

  it 'routes to #edit' do
    expect(get: '/tasks/1/edit').to route_to('tasks#edit', id: '1')
  end

  it 'routes to #create' do
    expect(post: '/tasks').to route_to('tasks#create')
  end

  it 'routes to #update' do
    expect(put: '/tasks/1').to route_to('tasks#update', id: '1')
  end

  it "does't routes to #destroy" do
    expect(delete: '/tasks/1').not_to be_routable
  end

  it 'routes to #autocomplete' do
    expect(get: '/tasks/autocomplete').to route_to('tasks#autocomplete')
  end

  it 'routes to #filters with user as scope' do
    expect(get: '/tasks/user/filters').to route_to('tasks#filters', scope: 'user')
  end

  it 'routes to #items with user as scope' do
    expect(get: '/tasks/user/items').to route_to('tasks#items', scope: 'user')
  end

  it 'routes to #filters with teams as scope' do
    expect(get: '/tasks/teams/filters').to route_to('tasks#filters', scope: 'teams')
  end

  it 'routes to #items with teams as scope' do
    expect(get: '/tasks/teams/items').to route_to('tasks#items', scope: 'teams')
  end

  describe 'nested to events' do
    it 'routes to #new' do
      expect(get: '/events/1/tasks/new').to route_to('tasks#new', event_id: '1')
    end

    it 'routes to #create' do
      expect(post: '/events/1/tasks').to route_to('tasks#create', event_id: '1')
    end
  end
end
