#!/usr/bin/perl

use Getopt::Long;
Getopt::Long::Configure("bundling");

my $iterations = 1000;

my $laternate = '';
my @categoryTypes = qw( G R I N H);
$maxResources = 25;

GetOptions ('a' => \$alternate, 'i=i' => \$iterations);

sub assignRandom {
  my ($max) = @_;
  my %resources;
  foreach my $type (@categoryTypes) {
    $resources{$type} = 0;
  }
  # assign resources randomly
if ($alternate) {
   for (my $i=1;$i<=$maxResources;$i++) {
      # Assign resource unit $i to a random category
      my $category = $categoryTypes[ int (rand scalar(@categoryTypes)) ];
      $resources{$category}++;
   }
} else {
   my @types = @categoryTypes;
   for (my $i=0;$i<@categoryTypes-1;$i++) {
      my $index = int (rand scalar @types);
      my $type = $types[ $index ];
      @types = ( @types[0..$index - 1], @types[$index+1..$#types] );
      $resources{$type} = int (rand ($max + 1));
      $max -= $resources{$type};
   }
   $type = @types[0];
   $resources{$type} = $max;
}
   return %resources;
}

my @totals;
my %resources;

for (my $i=0;$i<$iterations;$i++) {
  %resources = assignRandom($maxResources);
  foreach $v (values %resources) {
    $totals[$v]++;
  }
}
for (my $j=0;$j<=$maxResources;$j++) {
  print "$j: \t$totals[$j]\n";
}
