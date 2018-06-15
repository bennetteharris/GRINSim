sub diversify {
   local ($population,$teams,$depth) = @_;
   # Go through each team and mark the locked people
   # by recording what each provides

   local @teamNeeds;
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teamNeeds[$team] = {};
      if ($depth >=1) { $teamNeeds[$team]{'G'} = 1; } else { $teamNeeds[$team]{'G'} = 0; }
      if ($depth >=2) { $teamNeeds[$team]{'R'} = 1; } else { $teamNeeds[$team]{'R'} = 0; }
      if ($depth >=3) { $teamNeeds[$team]{'I'} = 1; } else { $teamNeeds[$team]{'I'} = 0; }
      if ($depth >=4) { $teamNeeds[$team]{'N'} = 1; } else { $teamNeeds[$team]{'N'} = 0; }
      foreach $person (@{$teams->[$team]}) {
         if ($population->{'people'}[$person]{'prefG'} and $teamNeeds[$team]{'G'}) {
            $teamNeeds[$team]{'G'} = 0;
            $population->{'people'}[$person]{'provides'} = 'G';
         } elsif ($population->{'people'}[$person]{'prefR'} and $teamNeeds[$team]{'R'}) {
            $teamNeeds[$team]{'R'} = 0;
            $population->{'people'}[$person]{'provides'} = 'R';
         } elsif ($population->{'people'}[$person]{'prefI'} and $teamNeeds[$team]{'I'}) {
            $teamNeeds[$team]{'I'} = 0;
            $population->{'people'}[$person]{'provides'} = 'I';
         } elsif ($population->{'people'}[$person]{'prefN'} and $teamNeeds[$team]{'N'}) {
            $teamNeeds[$team]{'N'} = 0;
            $population->{'people'}[$person]{'provides'} = 'N';
         } else {
            $population->{'people'}[$person]{'provides'} = '';
         }
      }
   }

 # Now go through each team searching for swaps
 for (my $team=0;$team<$teamsPerPopulation;$team++) {
   # First Pass: Mutually Beneficial Trades
   # for all teams beyond this one, see if mutually beneficial trades exist.
#print "Team ",$team+1," has needs.\n";
   for (my $swapTeam=$team+1;$swapTeam<$teamsPerPopulation;$swapTeam++) {
#print "..Asking team ",$swapTeam+1,"\n";
      # We keep swapping so long as we can be mutually beneficial
      while (youCanHelpMe($team,$swapTeam) and youCanHelpMe($swapTeam,$team)) {
         # Do the swap, both in the teams array and in population hash
         # candidateA = person from swapTeam to swap in
         # candidateB = person from team to swap out
         my $candidateA = whoCanHelpMe($team,$swapTeam);
         my $candidateB = whoCanHelpMe($swapTeam,$team);
#print "Swapping person ",1+$candidateA," from team ",$swapTeam+1," with person ",1+$candidateB," from team ",$team+1,"\n";
#print "  to add ".$population->{'people'}[$candidateA]{'provides'}." to team ",$team+1," and ";
#print $population->{'people'}[$candidateB]{'provides'}." to team ",$swapTeam+1,".\n";
         $population->{'people'}[$candidateA]{'team'} = $team + 1;
         $population->{'people'}[$candidateB]{'team'} = $swapTeam + 1;
         for (my $member=0;$member<$peoplePerTeam;$member++) {
            if ($teams->[$team][$member] == $candidateB) {$teams->[$team][$member] = $candidateA;}
         }
         for (my $member=0;$member<$peoplePerTeam;$member++) {
            if ($teams->[$swapTeam][$member] == $candidateA) {$teams->[$swapTeam][$member] = $candidateB;}
         }
         $teamNeeds[$team]{$population->{'people'}[$candidateA]{'provides'}} = 0;
         $teamNeeds[$swapTeam]{$population->{'people'}[$candidateB]{'provides'}} = 0;
      } 
   }

   # Second Pass: Beneficial Trades for me, not harmful to them
   # for all teams, see if suitable trades exist.
   # per Chris, we do this "up and down"
   for (my $swapTeam=$team-1;$swapTeam>=0;$swapTeam--) {
      # We don't try to swap with ourselves :-)
      if ($swapTeam != $team) {
         # We keep swapping so long as we can be beneficial
         while (youCanHelpMe($team,$swapTeam)) {
            # Do the swap, both in the teams array and in population hash
            # candidateA = person from swapTeam to swap in
            # candidateB = person from team to swap out
            my $candidateA = whoCanHelpMe($team,$swapTeam);
            my $candidateB = whoCanISpare($team);
#print "Swapping person ",1+$candidateA," from team ",$swapTeam+1," with person ",1+$candidateB," from team ",$team+1,"\n";
#print "  to add ".$population->{'people'}[$candidateA]{'provides'}." to team ",$team+1," and ";
#print "nothing to team ",1+$swapTeam,".\n";
            $population->{'people'}[$candidateA]{'team'} = $team + 1;
            $population->{'people'}[$candidateB]{'team'} = $swapTeam + 1;
            for (my $member=0;$member<$peoplePerTeam;$member++) {
               if ($teams->[$team][$member] == $candidateB) {$teams->[$team][$member] = $candidateA;}
            }
            for (my $member=0;$member<$peoplePerTeam;$member++) {
               if ($teams->[$swapTeam][$member] == $candidateA) {$teams->[$swapTeam][$member] = $candidateB;}
            }
            $teamNeeds[$team]{$population->{'people'}[$candidateA]{'provides'}} = 0;
         }
      }
   }

   for (my $swapTeam=$team+1;$swapTeam<$teamsPerPopulation;$swapTeam++) {
      # We don't try to swap with ourselves :-)
      if ($swapTeam != $team) {
         # We keep swapping so long as we can be beneficial
         while (youCanHelpMe($team,$swapTeam)) {
            # Do the swap, both in the teams array and in population hash
            # candidateA = person from swapTeam to swap in
            # candidateB = person from team to swap out
            my $candidateA = whoCanHelpMe($team,$swapTeam);
            my $candidateB = whoCanISpare($team);
#print "Swapping person ",1+$candidateA," from team ",$swapTeam+1," with person ",1+$candidateB," from team ",$team+1,"\n";
#print "  to add ".$population->{'people'}[$candidateA]{'provides'}." to team ",$team+1," and ";
#print "nothing to team ",1+$swapTeam,".\n";
            $population->{'people'}[$candidateA]{'team'} = $team + 1;
            $population->{'people'}[$candidateB]{'team'} = $swapTeam + 1;
            for (my $member=0;$member<$peoplePerTeam;$member++) {
               if ($teams->[$team][$member] == $candidateB) {$teams->[$team][$member] = $candidateA;}
            }
            for (my $member=0;$member<$peoplePerTeam;$member++) {
               if ($teams->[$swapTeam][$member] == $candidateA) {$teams->[$swapTeam][$member] = $candidateB;}
            }
            $teamNeeds[$team]{$population->{'people'}[$candidateA]{'provides'}} = 0;
         }
      }
   }
 }
sub dumpteams {
for (my $team=0;$team<$teamsPerPopulation;$team++) {
 print $team+1,": ";
for (my $i=0;$i<6;$i++) {
print $teams->[$team][$i]+1," ";
}
print "\n";
}
}

#dumpteams();
   return;
}

sub whoCanHelpMe {
   my ($receiver,$giver) = @_;
#print "asking for donations from team ",$giver+1,"\n";
   foreach $person (@{$teams->[$giver]}) {
#print " examining person ",$person+1,", they provide ",$population->{'people'}[$person]{'provides'},".\n";
      if ($population->{'people'}[$person]{'provides'} eq '') {
         if ($population->{'people'}[$person]{'prefG'} and $teamNeeds[$receiver]{'G'}) {
            $population->{'people'}[$person]{'provides'} = 'G';
            $teamNeeds[$receiver]{'G'} = 0;
            return $person;
         } elsif ($population->{'people'}[$person]{'prefR'} and $teamNeeds[$receiver]{'R'}) {
            $population->{'people'}[$person]{'provides'} = 'R';
            $teamNeeds[$receiver]{'R'} = 0;
            return $person;
         } elsif ($population->{'people'}[$person]{'prefI'} and $teamNeeds[$receiver]{'I'}) {
            $population->{'people'}[$person]{'provides'} = 'I';
            $teamNeeds[$receiver]{'I'} = 0;
            return $person;
         } elsif ($population->{'people'}[$person]{'prefN'} and $teamNeeds[$receiver]{'N'}) {
            $population->{'people'}[$person]{'provides'} = 'N';
            $teamNeeds[$receiver]{'N'} = 0;
            return $person;
         }
#} else {
#print " not person ",$person+1,", they provide ",$population->{'people'}[$person]{'provides'},".\n";
      }
   }
   print "ERROR: whoCanHelpMe failed to find helpful person after youCanHelpMe returned success\n";
   return 0;
}

sub youCanHelpMe {
   my ($receiver,$giver) = @_;
   foreach $person (@{$teams->[$giver]}) {
      if ($population->{'people'}[$person]{'provides'} eq '') {
         if ($population->{'people'}[$person]{'prefG'} and $teamNeeds[$receiver]{'G'}) {
            return 1;
         } elsif ($population->{'people'}[$person]{'prefR'} and $teamNeeds[$receiver]{'R'}) {
            return 1;
         } elsif ($population->{'people'}[$person]{'prefI'} and $teamNeeds[$receiver]{'I'}) {
            return 1;
         } elsif ($population->{'people'}[$person]{'prefN'} and $teamNeeds[$receiver]{'N'}) {
            return 1;
         }
      }
   }
   return 0;
}

sub whoCanISpare {
   my ($team) = @_;
   my $member = 0;
   while ($population->{'people'}[$teams->[$team][$member]]{'provides'} ne '' and $member < $peoplePerTeam - 1) { $member++; }
#print "Can spare entry $member from team ",1+$team,". This is person ",$teams->[$team][$member]+1,"\n";
   return $teams->[$team][$member];
}


1;
