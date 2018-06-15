use GRINCore;
require "Diversifier.pl";

my $model = 'DiversifiedFamilies';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   # Assign first n people to team 1, next n people to team 2, etc.
   my @teams;
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      for (my $person=$team*$peoplePerTeam;$person<($team+1)*$peoplePerTeam;$person++) {
         $population->{'people'}[$person]{'team'} = $team + 1;
         push(@{$teams[$team]},$person);
      }
   }

   diversify($population,\@teams,4);
   return @teams;
};
