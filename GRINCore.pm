package GRINCore;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
&assignRandom
@categoryTypes 
$weightH
@percentiles
@modelTypes
@populationTypes
$peoplePerTeam
$teamsPerPopulation
$resourceUnitsPerPerson
$maxResourceUnitsPerPerson
$minResourceUnitsPerPerson
$peoplePerPopulation
$showHiLo
$fixedData
$showRaw
$iterations
$showDetails
$likeChris
$roundEffective
$alternate
$preferenceMargin
);

use Getopt::Long;
Getopt::Long::Configure("bundling");

BEGIN {
 @categoryTypes = qw( G R I N H );
 $weightH = 0.5;
 @percentiles = qw( 10 20 30 40 50 60 70 80 90 100 );
# @percentiles = qw( 20 50 80 100 );
 @modelTypes = ( );
 @populationTypes = qw( );
 $peoplePerTeam = 6;
 $teamsPerPopulation = 10;
 $resourceUnitsPerPerson = 13;
 $maxResourceUnitsPerPerson = 26;
 $minResourceUnitsPerPerson = 0;
 $preferenceMargin = 1/3; # percentage

 $peoplePerPopulation = $peoplePerTeam * $teamsPerPopulation;

 $showHiLo = '';      # default: do not show High and Low values along with averages in final results
 $fixedData = '';     # default: use random data, not Chris's fixed data.
 $showRaw = '';       # default: do not display raw data for each person in each pool.
 $iterations = 1;     # default: run for 1 set of populations
 $showDetails = '';   # default: do not display results for each population, only a summary
 $likeChris = 1;      # default: do percentiles like Chris 
 $roundEffective = '' # default: do not round effective scores
 $showHelp = '';      # defaut: do not show help
 $alternate = '';     # default: do not use alternate random distribution method

GetOptions ('hilo' => \$showHiLo,
            'a' => \$alternate,
            'h' => \$showHelp,
            'help' => \$showHelp,
            'f' => \$fixedData,
            'r' => \$showRaw,
            'c' => \$likeChris,
	    'e' => \$roundEffective,
            'i=i' => \$iterations,
            'n=i' => \$iterations,
            'd' => \$showDetails);
}

print "$iterations iterations\n";

sub assignRandom {
  my ($max) = @_;
  my %resources;
  foreach my $type (@categoryTypes) {
    $resources{$type} = 0;
  }
  # assign resources randomly
if ($alternate) {
   for (my $i=1;$i<=$resourceUnitsPerPerson;$i++) {
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

if ($showHelp) {
   print "NAME
	GRINSim.pl - an elitism simulation and comparison tool

SYNOPSIS
	$0 [ options ]

DESCRIPTION
	This simulator generates multiple sets of random populations and calculates their adaptive capacity scores
        when configured into teams according to various criteria.

COMMAND LINE OPTION
	-h, --help
		Display this help, and exit
	--hilo	Display High and Low team values along with averages in final results
	-f	Use fixed data (primarily for testing)
	-r	Display raw population data
	-c	Interpolate percentiles (unlike Chris)
	-e      Round up effective scores      
	-d	Show details, that is, the AC average date for each iteration, as well as the final summary
	-i integer, -n integer
		Number of iterations (unique complete populations) to run.
		If you are planning to run large numbers of iterations, you might wish to 
		time this process first, to get an estimate of how long it might take. A command
		like
			date; $0 -i 100; date
		would show how long 100 iterations took.
	
";
   exit;
}
1;
