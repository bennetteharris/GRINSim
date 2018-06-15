use GRINCore;
use List::Util 	qw [min max];

my $model = 'LeadByBest';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   # sort by highest effective score.
   @{$population->{'people'}} = sort { ($b->{'eMax'} <=> $a->{'eMax'}) * 100 + ($a->{'index'} <=> $b->{'index'})
                                        } @{$population->{'people'}};

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
         if ($population->{'people'}[$person]{"e$need"} > $best) {
            $best = $population->{'people'}[$person]{"e$need"};
            $bestArea = $need;
         }
      }
      # need in $bestArea is satisfied
      $population->{'people'}[$person]{'provides'} = $bestArea;
      #$teamsNeed[$team]{$bestArea} = 0;
      delete $teamsNeed[$team]{$bestArea};
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
         $population->{'people'}[$bestPerson]{'provides'} = $bestNeed;
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
         $population->{'people'}[$bestPerson]{'team'} = $team + 1;
         push(@{$teams[$team]},$bestPerson);
      }
   }

   return @teams;
};
