use GRINCore;
require "Diversifier.pl";

my $model = 'DiversifiedIG';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   # first sort by prefG, then prefR, then prefI, then prefN, then index.  Perl > 5.7 has a stable sort
   @{$population->{'people'}} = sort { ($a->{'prefN'} <=> $b->{'prefN'}) * 100000 +
                                       ($a->{'prefI'} <=> $b->{'prefI'}) * 10000 +
                                       ($a->{'prefR'} <=> $b->{'prefR'}) * 1000 +
                                       ($a->{'prefG'} <=> $b->{'prefG'}) * 100 +
                                       ($a->{'index'} <=> $b->{'index'}) * 1
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

   diversify($population,\@teams,4);
   return @teams;
};
