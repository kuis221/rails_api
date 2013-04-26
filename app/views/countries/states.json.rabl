object false

node :states do
  @country.states.map{|k,info| {id: k, name: info['name']}}
end
