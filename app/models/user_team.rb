class UserTeam < ApplicationRecord
  self.table_name = :user_groups

  has_paper_trail on: %i[create update destroy]

  belongs_to :user
  belongs_to :team, foreign_key: 'group_id', inverse_of: :user_teams

  validates_uniqueness_of :user_id, scope: :group_id, on: :create,
                          :message=> 'This user is already a member of the team.'

  # This will return all possibly relevant PaperTrail::Version results
  def self.paper_trail_by_team_id(team_id)
    PaperTrail::Version.
      where(item_type: 'UserTeam').
      where(%(object_changes @> '{"group_id":[?]}'), team_id)
=begin

In theory, there's no path through the web site where someone could grab a UserTeam record and alter
the user_id without making other changes. To catch that scenario, we'd need to add the following:

```
.or(
  PaperTrail::Version.where(item_type: 'UserTeam').where(%(object @> '{"group_id": ?}'), team_id)
)
```

which looks more complicated in Ruby than in the resulting SQL query

=end
  end
end
