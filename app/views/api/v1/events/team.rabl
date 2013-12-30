object false

child @users => :users do
  extends "api/v1/users/user"
end

child @teams => :teams do
  extends "api/v1/teams/team"
end