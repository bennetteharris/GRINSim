use GRINCore;
use List::Util 	qw [min max];

my $model = 'LeadByAllStars';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;

   # First we run the TopTeams code, then we assign leaders to the new teams by using TT 1 from best to worst eMax score,
   # then TT2 from best to worst, ... until all teams have a leader.  Once a leader is selected for each team, the rest
   # are filled in via NFL draft.
#require "TopTeam.pl";
   my $createTeams = ${"createTopTeamTeams"};
   my @TT = [ &$createTeams($population) ];
   
   # sort by team (low to high) and highest effective score (high to low).
   @{$population->{'people'}} = sort { ($a->{'team'} <=> $b->{'team'}) * 10000
                                     + ($b->{'eMax'} <=> $a->{'eMax'})
                                     + ($a->{'index'} <=> $b->{'index'})
                                        } @{$population->{'people'}};
   # This sort means that the person numbers currently assigned to teams in @TT is meaningless, but that's OK
   # since we are going to reassign them all now based on this new sort.  However, we do need to clear the current
   # $person{'team'} and $person{'provides'}before the NFL draft portion.

   # Assign first n people to teams 1 -- n, then allow teams to select additional members in NFL draft pick style
   # Since we number teams from 0 to n - 1, the algorithm used here is:
   # "picks" 0 to n - 1 are the top n people.  Then,
   # For pick n to totalPopulation -1,
   #   if pick / n is even, team k mod n picks next
   #   if pick / n is odd, team n - 1 - (k mod n) picks next
   my @teams;
   my @teamsNeed;
   my $person;
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      $teamsNeed[$team] = {'G'=>1,'R'=>1,'I'=>1,'N'=>1}; # all teams initially need everything
      $person = $team; # person# = team# for top n people
      push(@{$teams[$team]},$person);
      $population->{'people'}[$person]{'team'} = $team + 1;
      # decide what this initial person supplies
      my $best = -1;
      my $bestArea = "";
      foreach $need (keys %{$teamsNeed[$team]}) {
         if ($population->{'people'}[$person]{"e$need"} > $best and $population->{'people'}[$person]{"pref$need"}) {
            $best = $population->{'people'}[$person]{"e$need"};
            $bestArea = $need;
         }
      }
      # If we found a best preferred area, then
      # need in $bestArea is satisfied
      if ($best >= 0) {
         # we found a best
         $population->{'people'}[$person]{'provides'} = "*$team$bestArea"; # * marks the leader of the team and when picked for later analysis
         #$teamsNeed[$team]{$bestArea} = 0;
         delete $teamsNeed[$team]{$bestArea};
      } else {
         # we did not
         $population->{'people'}[$person]{'provides'} = "*$team"; # * marks the leader of the team and when picked for later analysis
      }
   }
   # Next we clear 'team' and 'provides' for the remaining people
   for ($person=$teamsPerPopulation;$person<$peoplePerPopulation;$person++) {
      $population->{'people'}[$person]{'team'} = undef;
      $population->{'people'}[$person]{'provides'} = '';
   }
   # Now we "NFL draft" pick the remaining team members, starting with team n
   for (my $pick=$teamsPerPopulation;$pick<$peoplePerPopulation;$pick++) {
      if ( int($pick / $teamsPerPopulation) % 2 ) {
         $team = $teamsPerPopulation - 1 - ($pick % $teamsPerPopulation);
      } else {
         $team = $pick % $teamsPerPopulation;
      }
      # it is $team's turn to pick - pick the best person that fills a need
      my $bestVal = -1;
      my $bestPerson = -1;
      my $bestNeed = '';
      # Are there still needs to be met?
      if (keys %{$teamsNeed[$team]}) {
         # Yes - find best person to satisfy some remaining need
         for ($person=0;$person<=$#{$population->{'people'}};$person++) {
            foreach $need (keys %{$teamsNeed[$team]}) {
               if ($population->{'people'}[$person]{"e$need"} > $bestVal 
                     and $teamsNeed[$team]{$need}
                     and ! defined($population->{'people'}[$person]{'team'})) {
                  $bestVal = $population->{'people'}[$person]{"e$need"};
                  $bestPerson = $person;
                  $bestNeed = $need;
               }
            }
         }
         # person $bestPerson is my pick to satisfy need in $bestArea
         $population->{'people'}[$bestPerson]{'provides'} = "$pick$bestNeed"; # we record when picked for later analysis
         #$teamsNeed[$team]{$bestNeed} = 0;
         delete $teamsNeed[$team]{$bestNeed};
         $population->{'people'}[$bestPerson]{'team'} = $team + 1;
         push(@{$teams[$team]},$bestPerson);
      } else {
         # No - find remaining person with best eMax value
         for ($person=0;$person<=$#{$population->{'people'}};$person++) {
            if ($population->{'people'}[$person]{'eMax'} > $bestVal 
                  and ! defined($population->{'people'}[$person]{'team'})) {
               $bestVal = $population->{'people'}[$person]{'eMax'};
               $bestPerson = $person;
            }
         }
         # person $bestPerson is my pick as best remaining person
         $population->{'people'}[$bestPerson]{'provides'} = "$pick"; # we record when picked for later analysis
         $population->{'people'}[$bestPerson]{'team'} = $team + 1;
         push(@{$teams[$team]},$bestPerson);
      }
   }

   return @teams;
};
