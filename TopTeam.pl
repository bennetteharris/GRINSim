use GRINCore;
use List::Util 	qw [min max];

my $model = 'TopTeam';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population, @needsList) = @_;
   @needsList = ('G','R','I','N') if (! @needsList); #default list unless passed (as from LB20-3)
   # sort by highest effective score.
   @{$population->{'people'}} = sort { ($b->{'eMax'} <=> $a->{'eMax'}) * 100 + ($a->{'index'} <=> $b->{'index'})
                                        } @{$population->{'people'}};
   # Assign best n people to team 1, next best n people to team 2, etc.
   my @teams;
   my @teamNeeds;
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      @teamNeeds = @needsList;
      $alternatesNeeded = $peoplePerTeam - @teamNeeds;
      foreach $need (@teamNeeds) {
         my $bestVal = -1;
         my $bestPer = -1;
         my $person;
         for ($person=0;$person<=$#{$population->{'people'}};$person++) {
            if ($population->{'people'}[$person]{"e$need"} > $bestVal 
                  and ! defined($population->{'people'}[$person]{'team'})) {
               $bestVal = $population->{'people'}[$person]{"e$need"};
               $bestPer = $person;
            }
         }
         if ($bestVal >= 0 and $bestPer >= 0) {
            # We can fill this need with $bestPer
            $population->{'people'}[$bestPer]{'team'} = $team + 1;
            push(@{$teams[$team]},$bestPer);
         } # If we fail to fill a need, we select one more alternate
      }
      # At this point this team's need are satisfied as much as possible.  Fill out the team with highest eMins available
      for (my $slot=$#{$teams[$team]}+1;$slot<$peoplePerTeam;$slot++) {
         my $bestVal = -1;
         my $bestPer = -1;
         my $person;
         for ($person=0;$person<=$#{$population->{'people'}};$person++) {
            if ($population->{'people'}[$person]{"eMin"} > $bestVal
                  and ! defined($population->{'people'}[$person]{'team'})) {
               $bestVal = $population->{'people'}[$person]{"eMin"};
               $bestPer = $person;
            }
         }
         if ($bestVal >= 0 and $bestPer >= 0) {
            # We can fill this need with $bestPer
            $population->{'people'}[$bestPer]{'team'} = $team + 1;
            push(@{$teams[$team]},$bestPer);
         } else {
            # Failure here is fatal - there should always be someone to chose
            die ("Unable to fill team $team with alternates\n");
         }

      }
   }
   return @teams;
};
