use GRINCore;
use List::Util 	qw [min max];

my $model = 'LeadByBest20_3';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   local @teams;
   my $person;

   # First we run the TopTeams code, then we divide the population into top 20%/bottom80% tiers, and run LB on each tier
   my $createTeams = ${"createTopTeamTeams"};
   my @TT = [ &$createTeams($population, ('G','R','I','G','R','I')) ]; # with only 3 needs, we can select for each one twice.

   # sort by team (low to high) and highest effective score (high to low).
   @{$population->{'people'}} = sort { ($a->{'team'} <=> $b->{'team'}) * 10000
                                     + ($b->{'eMax'} <=> $a->{'eMax'}) * 100
                                     + ($a->{'index'} <=> $b->{'index'})
                                        } @{$population->{'people'}};
   # This sort means that the person numbers currently assigned to teams in @TT is meaningless, but that's OK
   # since we are going to reassign them all now based on this new sort.  However, we do need to clear the current
   # $person{'team'} and $person{'provides'}before the NFL draft portion.
   # Note that, because of the various sorts that occur, we need to be careful to keep team numbers fixed once set,
   # and we need to use $person{'index'} to record who is a member of a team.  Then later we will sort by index
   # so teams can easily access their members.

   # Now that we have our sort, we need to clear the 'team' and 'provides' fields.  We can do this here for the
   # entire population (rather than walking each tier separately) because we are already in the correct order
   # for the tiers
   for ($person = 0;$person<$peoplePerPopulation;$person++) {
      $population->{'people'}[$person]{'team'} = undef;
      $population->{'people'}[$person]{'provides'} = '';
   }

   my $topPercent = 0.20;
   # Note that in each array slice = tier, the array subscripts are reset to start at 0.
   my @tier1 = @{$population->{'people'}}[0 .. (int($topPercent*$teamsPerPopulation)*$peoplePerTeam - 1)];
   my @tier2 = @{$population->{'people'}}[(int($topPercent*$teamsPerPopulation)*$peoplePerTeam) .. ($peoplePerPopulation - 1)];

   ################
   # TIER 1
   ################

   # Tier 1 consists of the people assigned to the first $topPercent teams by TT.
   # We use the same team numbers, but now reassign the people by LB.
   $firstTeam = 0 ;
   $lastTeam = int($topPercent*$teamsPerPopulation) - 1;

   buildTier(\@tier1);

   ################
   # TIER 2
   ################

   # Tier 2 consists of the people assigned to the remaining teams by TT.
   # We use the same team numbers, but now reassign the people by LB.
   $firstTeam = int($topPercent*$teamsPerPopulation) ;
   $lastTeam = $teamsPerPopulation - 1;
   buildTier(\@tier2);

   # Since each person carries an 'index' field, we can merge the two tiers back together and then sort on index

   @{$population->{'people'}} = sort { $a->{'index'} <=> $b->{'index'} } (@tier1, @tier2);

   return @teams;

sub buildTier {
   my ($tier) = @_;
   # sort by highest effective score.
   @{$tier} = sort { ($b->{'eMax'} <=> $a->{'eMax'}) * 100 + ($a->{'index'} <=> $b->{'index'})
                                        } @{$tier};

   # Assign first n people to teams 1 -- n, then allow teams to select additional members in NFL draft pick style
   # Since we number teams from 0 to n - 1, the algorithm used here is:
   # "picks" 0 to n - 1 are the top n people.  Then,
   # For pick n to totalPopulation -1,
   #   if pick / n is even, team k mod n picks next
   #   if pick / n is odd, team n - 1 - (k mod n) picks next
   my @teamsNeed;
   for (my $team=$firstTeam;$team<=$lastTeam;$team++) {
      $teams[$team] = [];
      $teamsNeed[$team] = {'G'=>1,'R'=>1,'I'=>1,'N'=>1}; # all teams initially need everything
      $person = $team - $firstTeam; # person# = team# for top n people, adjusted to start at 0 offset
#print "adding person $person with index " . $tier->[$person]{'index'} . " to team $team\n";
      push(@{$teams[$team]},$tier->[$person]{'index'});
      $tier->[$person]{'team'} = $team + 1;
      # decide what this initial person supplies
      my $best = -1;
      my $bestArea = "";
      foreach $need (keys %{$teamsNeed[$team]}) {
         if ($tier->[$person]{"e$need"} > $best) {
            $best = $tier->[$person]{"e$need"};
            $bestArea = $need;
         }
      }
      # need in $bestArea is satisfied
      $tier->[$person]{'provides'} = $bestArea;
      #$teamsNeed[$team]{$bestArea} = 0;
      delete $teamsNeed[$team]{$bestArea};
   }
   # Now we "NFL draft" pick the remaining team members, starting with team n
   for (my $pick=$lastTeam-$firstTeam+1;$pick<($lastTeam-$firstTeam+1)*$peoplePerTeam;$pick++) {
      if ( int($pick / ($lastTeam-$firstTeam+1)) % 2 ) {
         $team = $lastTeam - ($pick % ($lastTeam-$firstTeam+1));
      } else {
         $team = $firstTeam + ($pick % ($lastTeam-$firstTeam+1));
      }
      # it is $team's turn to pick - pick the best person that fills a need
      my $bestVal = -1;
      my $bestPerson = -1;
      my $bestNeed = '';
      # Are there still needs to be met?
      if (keys %{$teamsNeed[$team]}) {
         # Yes - find best person to satisfy some remaining need
         for ($person=0;$person<=$#{$tier};$person++) {
            foreach $need (keys %{$teamsNeed[$team]}) {
               if ($tier->[$person]{"e$need"} > $bestVal 
                     and $teamsNeed[$team]{$need}
                     and ! defined($tier->[$person]{'team'})) {
                  $bestVal = $tier->[$person]{"e$need"};
                  $bestPerson = $person;
                  $bestNeed = $need;
               }
            }
         }
         # person $bestPerson is my pick to satisfy need in $bestArea
         $tier->[$bestPerson]{'provides'} = $bestNeed;
         #$teamsNeed[$team]{$bestNeed} = 0;
         delete $teamsNeed[$team]{$bestNeed};
         $tier->[$bestPerson]{'team'} = $team + 1;
         push(@{$teams[$team]},$tier->[$bestPerson]{'index'});
#print "adding person $bestPerson with index " . $tier->[$bestPerson]{'index'} . " to team $team\n";
      } else {
         # No - find remaining person with best eMax value
         for ($person=0;$person<=$#{$tier};$person++) {
            if ($tier->[$person]{'eMax'} > $bestVal 
                  and ! defined($tier->[$person]{'team'})) {
               $bestVal = $tier->[$person]{'eMax'};
               $bestPerson = $person;
            }
         }
         # person $bestPerson is my pick as best remaining person
         $tier->[$bestPerson]{'team'} = $team + 1;
         push(@{$teams[$team]},$tier->[$bestPerson]{'index'});
#print "adding person $bestPerson with index " . $tier->[$bestPerson]{'index'} . " to team $team\n";
      }
   }
}

};
