#!/usr/bin/perl
use Data::Dumper; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Indent = 1; $Data::Dumper::Terse = 1;

BEGIN{ push @INC, '.';}

use strict 'vars';
use GRINCore;

require "Naturalism.pl";
require "InterestGroups.pl";
require "LeastVulnerable.pl";
require "LeadByLeastVulnerable.pl";
require "DiversifiedFamilies.pl";
require "DiversifiedFamilies1.pl";
require "DiversifiedFamilies2.pl";
require "DiversifiedLeadByLeastVulnerable.pl";
require "DiversifiedIG.pl";
require "TopTeam.pl";
require "LeadByAllStars.pl";
require "LeadByBest.pl";
require "LeadByScarcity.pl";
require "LeadByBest20.pl";
require "LeadByBest50.pl";
require "LeadByBest80.pl";
require "LeadByBest20-3.pl";
require "LeadByBest20-2.pl";

require "Clone.pl";
require "Equal.pl";
require "Unequal.pl";

sub assignEffectiveResources {
   # for each $category, calculate "e$category} resource as 
   # sum of $category resource and $weightH*H resource 
   my %resources = ( @_ );
   $resources{'Total'} = 0;
   $resources{'eTotal'} = 0;
   $resources{'eMin'} = 999999;
   $resources{'eMax'} = 0;
   foreach my $category (@categoryTypes) {
      if ($category ne 'H') {
         if ($likeChris) {
            # like Chris: round up so we have integers only when we add H to other categories.
            $resources{"e$category"} = $resources{$category} + int ($weightH*$resources{'H'} + 0.9)
         } else {
            $resources{"e$category"} = $resources{$category} + $weightH*$resources{'H'}
         }
         $resources{'eTotal'} += $resources{"e$category"};
         if ($resources{"e$category"} > $resources{'eMax'}) { $resources{'eMax'} = $resources{"e$category"} }
         if ($resources{"e$category"} < $resources{'eMin'}) { $resources{'eMin'} = $resources{"e$category"} }
      }
      $resources{'Total'} += $resources{$category};
   }
   my $eAvg = $resources{'eTotal'} / $#categoryTypes; # "last index" of @categoryTypes = count -1, just right for excluding H
   foreach my $category (@categoryTypes) {
      if ($category ne 'H') {
         if ($resources{"e$category"} > (1 + $preferenceMargin)*$eAvg) {
            # mark this function as preferred
            $resources{"pref$category"} = 1
         } else {
            $resources{"pref$category"} = 0
         }
      }
   }
   return %resources;
}

sub permuteTeam {
   # return all permutations of length $len from @list
   my ($len,@list) = @_;
   my @perms = ();
   # if @list is empty or $len = 0 there are no perms
   if (scalar(@list) == 0 or $len == 0) { return (\@list) }
   # if @list has length 1 and $len >= 1, there is only one permutation
   if (scalar(@list) == 1 and $len >= 1) { return (\@list) }
   for (my $i=0;$i<@list;$i++) {
      my $m = $list[$i];
      my @remList = ( @list[0..$i-1], @list[$i+1..$#list] );
      foreach my $p (permuteTeam($len-1,@remList)) {
         push @$p, $m;
	 push @perms, $p;
      }
   }
   return @perms;
}

sub evaluateTeam {
   my ($p,$t) = @_;
   my $value = 1;
   for (my $i=0;$i<=$#categoryTypes;$i++) {
      if ($categoryTypes[$i] ne 'H') { $value *= $p->{"people"}[$t->[$i]]{"e${categoryTypes[$i]}"}; }
   }
   return $value;
}

sub computeTeamACs {
   my ($population) =  @_;
   my $teams =  $population->{'teams'};
   my @teamACs;
   # calculate maximum possible AC for each team
   for (my $team=0;$team<@$teams;$team++) {
      $teamACs[$team] = 0;
      foreach my $t (permuteTeam(6,@{$teams->[$team]})) {
         my $value = evaluateTeam($population,$t);
         if ($value > $teamACs[$team]) { $teamACs[$team] = $value; }
      }
   }
#print Dumper(\@teamACs);
   return @teamACs;
}

sub definePopulationTotals {
   my %populationTotals;
   foreach my $population (@populationTypes) {
      $populationTotals{$population} = { 'count' => 0, 'percentiles' => {} };
      for my $percent (@percentiles) {
         $populationTotals{$population}{'percentiles'}{$percent} = { 'high' => 0, 'low' => 0, 'total' => 0 };
      }
   }
}

sub readResources {
   my ($population) = @_;
   my @people = ();
   my %resources;
   my $line;
   my @values;
   foreach my $category (@categoryTypes) {
      $resources{$category} = 0;
   }
   # read resources from Fixed${population}.dat file
   my $filename = "Fixed${population}.dat";
   open INF,"<$filename" or die("Unable to open fixed data file $filename.\n");
   my $header = <INF>;
   my @keys = split /\s+/, $header;
   for (my $i=0;$i<$peoplePerPopulation;$i++) {
      $line = <INF> or die("Fixed data file $filename does not have sufficient data for $peoplePerPopulation people.\n");
      @values = split /\s+/, $line;
      for (my $j=0;$j<@keys;$j++) {
         $resources{$keys[$j]} = $values[$j];
      }
      %resources = assignEffectiveResources(%resources);
      $people[$i] = { %resources };
      $people[$i]{"index"} = $i;
   }
   close INF;
   return \@people;
}

sub definePopulations {
   my %populations;
   my $functionName;
   foreach my $population (@populationTypes) {
      $populations{$population} = { "people" => [], "teams" => [], "teamACs" => [] };
      if ($fixedData and -e "Fixed${population}.dat") {
            $functionName = "readResources";
            $populations{$population}{"people"} = $functionName->($population);
      } else {
         for (my $i=0;$i<$peoplePerPopulation;$i++) {
            $functionName = "assign${population}Resources";
            $populations{$population}{"people"}[$i] = { assignEffectiveResources( $functionName->() ) };
            $populations{$population}{"people"}[$i]{"index"} = $i;
         }
      }
   }
   return %populations;
}

sub sortn {
   return sort {$a <=> $b} @_;
}

sub computeTeamPercentiles {
   my ($population) =  @_;
   my %percentileScores;
   my @sortedACs = sortn @{$population->{'teamACs'}};
   for my $percent (@percentiles) {
      my $rawIndex = (100 - $percent) * $teamsPerPopulation / 100;
      my $intIndex = int $rawIndex;
      my $percentile;
      if ($rawIndex == 0) {
         $percentile = $sortedACs[$intIndex];
      } elsif ($intIndex != $rawIndex or $likeChris) {
         # Chris does not adjust percentiles in the usual way
         $percentile = $sortedACs[$intIndex]
      } else {
         $percentile = ($sortedACs[$intIndex - 1] + $sortedACs[$intIndex]) / 2;
      }
      $percentileScores{$percent} = $percentile;
   }
   return %percentileScores;
}


my %populations;
my %populationTotals = definePopulationTotals();
my $pt;
my $percent;

for my $mt (@modelTypes) {
print "\n",uc($mt),"\n";
my $createTeams = ${"create${mt}Teams"};
for (my $i=1;$i<=$iterations;$i++) {
   %populations = definePopulations();
   for $pt (@populationTypes) {
      $populations{$pt}{'teams'} = [ &$createTeams($populations{$pt}) ];
      $populations{$pt}{'teamACs'} = [ computeTeamACs($populations{$pt}) ];
      $populations{$pt}{'percentiles'} = { computeTeamPercentiles($populations{$pt}) };

   if ($showRaw) {
      # print column labels
      print "$pt\n";
      print "Index\tTeam\tTotal\tG\tR\tI\tN\tH\teG\teR\teI\teN\tprefG\tprefR\tPrefI\tPrefN\teMin\teMax\tProvides\n";
      # always print in orignal index order
      my @sortedPeople = @{$populations{$pt}{"people"}};
      @sortedPeople = sort { $a->{'index'} <=> $b->{'index'} } @sortedPeople;
      for (my $j=0;$j<$peoplePerPopulation;$j++) {
         my %person = %{$sortedPeople[$j]};
         print $person{'index'}+1,"\t$person{'team'}\t$person{'Total'}\t$person{'G'}\t$person{'R'}\t$person{'I'}\t$person{'N'}\t$person{'H'}\t";
         print "$person{'eG'}\t$person{'eR'}\t$person{'eI'}\t$person{'eN'}\t";
         print "$person{'prefG'}\t$person{'prefR'}\t$person{'prefI'}\t$person{'prefN'}\t$person{'eMin'}\t$person{'eMax'}\t$person{'provides'}";
         print "\n";
      }
      print "\n";
      
   }
   }

   # accumulate totals
   for $pt (@populationTypes) {
      for $percent (@percentiles) {
         if ($i == 1) {
            # first iteration only
            $populationTotals{$pt}{'percentiles'}{$percent}{'high'} = $populations{$pt}{'percentiles'}{$percent};
            $populationTotals{$pt}{'percentiles'}{$percent}{'low'} = $populations{$pt}{'percentiles'}{$percent};
            $populationTotals{$pt}{'percentiles'}{$percent}{'total'} = $populations{$pt}{'percentiles'}{$percent};
         } else {
            if ($populationTotals{$pt}{'percentiles'}{$percent}{'low'} > $populations{$pt}{'percentiles'}{$percent}) {
               $populationTotals{$pt}{'percentiles'}{$percent}{'low'} = $populations{$pt}{'percentiles'}{$percent};
            }
            if ($populationTotals{$pt}{'percentiles'}{$percent}{'high'} < $populations{$pt}{'percentiles'}{$percent}) {
               $populationTotals{$pt}{'percentiles'}{$percent}{'high'} = $populations{$pt}{'percentiles'}{$percent};
            }
            $populationTotals{$pt}{'percentiles'}{$percent}{'total'} += $populations{$pt}{'percentiles'}{$percent}
         }
      }
   }

   if ($showDetails) {
      # print column labels
      print "\t\t";
      for $percent (sortn @percentiles) { print "$percent\%\t" }
      print "\n";
      # print row labels and row data
      for $pt (sort @populationTypes) {
         print "$pt\t\t";
         for $percent (sortn @percentiles) { print int $populations{$pt}{'percentiles'}{$percent},"\t" }
         print "\n";
      }
      print "\n";
   }
}
   # print summary
   print "SUMMARY\n";
   if ($iterations == 0) {
      print "No data generated\n";
   } else {
      # print column labels
      print "\t\t";
      for $percent (sortn @percentiles) { print "$percent\%\t" }
      print "\n";
      # print row labels and row data
      for $pt (sort @populationTypes) {
         print "$pt";
         if ($showHiLo) {
            print "\t";
            for $percent (sortn @percentiles) {
               print "\t";
               print int $populationTotals{$pt}{'percentiles'}{$percent}{'low'};
            }
            print "\n";
         }
         print "\t";
         for $percent (sortn @percentiles) {
            print "\t";
            print int ($populationTotals{$pt}{'percentiles'}{$percent}{'total'} / $iterations);
         }
         print "\n";
         if ($showHiLo) {
            print "\t";
            for $percent (sortn @percentiles) {
               print "\t";
               print int $populationTotals{$pt}{'percentiles'}{$percent}{'high'};
            }
            print "\n\n";
         }
      }
   }
} # each modelType
