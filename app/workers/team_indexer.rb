class TeamIndexer
  @queue = :indexing

  def self.perform(team_id)
    team = Team.find(team_id)
    Sunspot.index(Event.with_team(team))
  end
end