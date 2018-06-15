use GRINCore;
use List::Util 	qw [min max];

my $model = 'LeastVulnerable';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   # sort by lowest effective score.
   @{$population->{'people'}} = sort { ($b->{'eMin'} <=> $a->{'eMin'}) * 100 + ($a->{'index'} <=> $b->{'index'})
                                        } @{$population->{'people'}};
   # Assign first n people to team 1, next n people to team 2, etc.
   my @teams;
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      for (my $person=$team*$peoplePerTeam;$person<($team+1)*$peoplePerTeam;$person++) {
         $population->{'people'}[$person]{'team'} = $team + 1;
         push(@{$teams[$team]},$person);
      }
   }
   return @teams;
};
