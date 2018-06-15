use GRINCore;
use List::Util 	qw [min max];

my $model = 'LeadByScarcity';

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   # First we must identify the most scarce resource.
   # Here this is defined as the reaource with the smallest effective value at the 25th %tile position
   # when sorted on that effective score.
   #
   # Because of the multiple sorts involved, we record the person's {'index'} in the team, and then sort
   # population by index before returning.

   my %teamResources = ('G'=>1,'R'=>1,'I'=>1,'N'=>1);
   my $scarcestResource = scarcest_resource($population,%teamResources);

   # we remove this scarcest entry from the list of resources, to prepare for the next round of picks
   delete $teamResources{$scarcestResource};
   # Now we choose team leaders from the top specialists on that list
   # If no specialists are left, take the top person remaining
   
   # Assign first n people to teams 1 -- n, then allow teams to select additional members in NFL draft pick style
   @{$population->{'people'}} = sort { ($b->{"e$scarcestResource"} <=> $a->{"e$scarcestResource"}) * 100 + ($a->{'index'} <=> $b->{'index'}) } @{$population->{'people'}};
   my @teams;
   my $person;
   my $round = 0; # first roud of picks
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      # if there is a best remaining specialist, use them
      $person = best_specialist($population,$scarcestResource);
      if ($person == -1) {
         # if there are no specialists left, take the best person left in this resource
         $person = best_remaining($population,$scarcestResource);
      }
      #push(@{$teams[$team]},$person);
      push(@{$teams[$team]},$population->{'people'}[$person]{'index'});
      $population->{'people'}[$person]{'team'} = $team + 1;
      $population->{'people'}[$person]{'provides'} = "*$scarcestResource";
   }

   # for successive rounds we "NFL draft" pick the remaining team members, starting with team n,
   # always choosing the top people for the scarcest remaining resource.
   while (keys %teamResources) {
      $round++;
      # which remaining resource is scarcest now?
      $scarcestResource = scarcest_resource($population,%teamResources);
      # we remove this scarcest entry from the list of resources, to prepare for the next round of picks
      delete $teamResources{$scarcestResource};

      # We make the current round of picks
      @{$population->{'people'}} = sort { ($b->{"e$scarcestResource"} <=> $a->{"e$scarcestResource"}) * 100 + ($a->{'index'} <=> $b->{'index'}) } @{$population->{'people'}};
      for (my $pick=$teamsPerPopulation*$round;$pick<$teamsPerPopulation*($round+1);$pick++) {
         # who picks next?
         if ( $round % 2 ) {
            $team = $teamsPerPopulation - 1 - ($pick % $teamsPerPopulation);
         } else {
            $team = $pick % $teamsPerPopulation;
         }
         # it is $team's turn to pick - pick the best available person with the best value for the scarcest resource
         # if there is a best remaining specialist,  use them
         $person = best_specialist($population,$scarcestResource);
         if ($person == -1) {
            # if there are no specialists left, take the best person left in this resource
            $person = best_remaining($population,$scarcestResource);
         }
         # person $person is my pick to satisfy need in $scarcestResource
         $population->{'people'}[$person]{'provides'} = $round.$scarcestResource;
         $population->{'people'}[$person]{'team'} = $team + 1;
         #push(@{$teams[$team]},$person);
         push(@{$teams[$team]},$population->{'people'}[$person]{'index'});
      }
   }

   # All the scarcest resources have been allocated - assign rest by least vulnerable
   $round++;
   while ($round < $peoplePerTeam) {
      # We make the next round of picks
      for (my $pick=$teamsPerPopulation*$round;$pick<$teamsPerPopulation*($round+1);$pick++) {
         # who picks next?
         if ( $round % 2 ) {
            $team = $teamsPerPopulation - 1 - ($pick % $teamsPerPopulation);
         } else {
            $team = $pick % $teamsPerPopulation;
         }
         # it is $team's turn to pick - pick the remaining person with the best eMin score
         my $bestVal = -1;
         my $bestPerson = -1;
         for ($person=0;$person<=$#{$population->{'people'}};$person++) {
            if ($population->{'people'}[$person]{'eMin'} > $bestVal 
                  and ! defined($population->{'people'}[$person]{'team'})) {
               $bestVal = $population->{'people'}[$person]{'eMin'};
               $bestPerson = $person;
            }
         }
         # person $bestPerson is my pick
         $population->{'people'}[$bestPerson]{'team'} = $team + 1;
         #push(@{$teams[$team]},$bestPerson);
         push(@{$teams[$team]},$population->{'people'}[$bestPerson]{'index'});
      }
      $round++;
   }

   @{$population->{'people'}} = sort { $a->{'index'} <=> $b->{'index'} } @{$population->{'people'}};
   return @teams;
};

sub best_specialist {
   my ($population,$resource) = @_;
   my $bestVal = -1;
   my $bestPerson = -1;
   for (my $person=0;$person<=$#{$population->{'people'}};$person++) {
      if ($population->{'people'}[$person]{"e$resource"} > $bestVal
            and $population->{'people'}[$person]{"pref$resource"}
            and ! defined($population->{'people'}[$person]{'team'})) {
         $bestVal = $population->{'people'}[$person]{"e$resource"};
         $bestPerson = $person;
      }
   }
   return $bestPerson;
}

sub best_remaining {
   my ($population,$resource) = @_;
   my $bestVal = -1;
   my $bestPerson = -1;
   for (my $person=0;$person<=$#{$population->{'people'}};$person++) {
      if ($population->{'people'}[$person]{"e$resource"} > $bestVal
            and ! defined($population->{'people'}[$person]{'team'})) {
         $bestVal = $population->{'people'}[$person]{"e$resource"};
         $bestPerson = $person;
      }
   }
   return $bestPerson;
}

sub scarcest_resource {
   my ($population,%teamResources) = @_;
   my @available = @{$population->{'people'}};
   for (my $person=$#available;$person>=0;$person--) {
      if (defined($available[$person]{"team"})) {
         splice(@available,$person,1); # ignore this entry for purposes of this search
      }
   }
   my $leastMin = 99999;
   my $scarcestResource = '';
   #my $testPos = int(0.25*$peoplePerPopulation);
   #my $testPos = int(0.10*$peoplePerPopulation);
   my $testPos = int(0.25*$#available);
   my $depthOfScarcest=99999;
   foreach $item (sort keys %teamResources) {
      #@available = sort { ($b->{"e$item"} <=> $a->{"e$item"}) * 100 + ($b->{'index'} <=> $a->{'index'}) } @available;
      # this particular process is not sensitive to the index order
      @available = sort { $b->{"e$item"} <=> $a->{"e$item"} } @available;
      if ($available[$testPos]{"e$item"} < $leastMin) {
         $leastMin = $available[$testPos]{"e$item"};
         $scarcestResource = $item;
         $depthOfScarcest = 0;
         # we need to see how deep this new minimal value goes
         for (my $person=$testPos+1;$person<=$#available;$person++) {
            if ($available[$person]{"e$item"} == $leastMin) { $depthOfScarcest++; }
         }
      } elsif ($available[$testPos]{"e$item"} = $leastMin) {
         my $testDepth = 0;
         # we have a tie with the min - is it shallower?
         for (my $person=$testPos+1;$person<=$#available;$person++) {
            if ($available[$person]{"e$item"} == $leastMin) { $testDepth++; }
         }
         # if it is shallower, then it is scarcer
         if ($testDepth < $depthOfScarcest) {
            $scarcestResource = $item;
            $depthOfScarcest = $testDepth;
         }
      }
   }
   return $scarcestResource;
}

