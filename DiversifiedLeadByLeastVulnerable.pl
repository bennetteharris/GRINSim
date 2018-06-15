use GRINCore;
use List::Util 	qw [min max];
require "Diversifier.pl";

my $model = 'DiversifiedLeadByLeastVulnerable';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   # sort by lowest effective score.
   @{$population->{'people'}} = sort { ($b->{'eMin'} <=> $a->{'eMin'}) * 100 + ($a->{'index'} <=> $b->{'index'})
                                        } @{$population->{'people'}};
   # Assign first k people to teams 1 -- n, next k people to teams n -- 1, etc. (NFL draft pick style)
   # Since we number teams from 0 to n - 1, the algorithm used here is
   # if k / n is even, assign person k to team k mod n
   # if k / n is odd, assign person k to team n - 1 - (k mod n)
   my @teams;
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
   }
   for (my $person=0;$person<$peoplePerPopulation;$person++) {
      if ( int($person / $teamsPerPopulation) % 2 ) {  
#         push(@{$teams[$teamsPerPopulation - 1 - ($person % $teamsPerPopulation)]},$person);
         $team = $teamsPerPopulation - 1 - ($person % $teamsPerPopulation);
      } else {
#         push(@{$teams[$person % $teamsPerPopulation]},$person);
         $team = $person % $teamsPerPopulation;
      }
      $population->{'people'}[$person]{'team'} = $team + 1;
      push(@{$teams[$team]},$person);
   }
   diversify($population,\@teams,4);
   return @teams;
};
