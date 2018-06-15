use GRINCore;

my $model = 'TypeName'; # User edits this type name, and "requires" this file in GRINSim.pl

push @modelTypes, $model;

${"create${model}Teams"} = sub {
   my ($population) = @_;
   my @teams;

###################################################################################
# Start of user-defined code for populating @teams from @populations for this model
###################################################################################

# User code must populate @{$teams[$team]} for $teams = 0, 1, ..., n - 1 with a list
# of persons.  These persons MUST be numbers representing the array subscript to that 
# person within the @{$population->{'people'}} array.  If you only sort the array
# once in generating the teams, then you may reliably use the natural subscripts
# within the array.  However, if the team-generating process requires complex manipulations,
# it is recommended that you populate the @{$teams[$team]} teams array using the fixed
# $population->{'people'}[$person]{'index'} value associated with eache person record,
# as this number moves with the record regardless how sorted, and then as a last step
# re-sort the @{$population->{'people'}} array.  Both approaches are illustrated below.

##################
# Method 1
##################
# Use natural array subscripts

   # Any sorts must happen before team assignment starts.
   # Multiple sorts are possible, but once completed, array subscripts
   # must stay fixed.

   # Example: sort by highest effective scorei, decreasing.
   @{$population->{'people'}} = sort { $b->{'eMax'} <=> $a->{'eMax'} } @{$population->{'people'}};

   # Assign first n people to team 1, next n people to team 2, etc.
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      for (my $person=$team*$peoplePerTeam;$person<($team+1)*$peoplePerTeam;$person++) {
         # Optional, but highly recommended, is to record the assigned team as part of the 
         # person's record.  We assign $team + 1 so team numbers are in the more human-friendly
         # 1, 2, ..., n form.
         $population->{'people'}[$person]{'team'} = $team + 1;
         # Note we are pushing $person, the natural @population subscript, onto the team array.
         push(@{$teams[$team]},$person);
      }
   }

##################
# Method 2
##################
# Use fixed 'index' field of person record

   # Sorts may happen as needed, so long as @population array is placed back in 'index' order 
   # before returning.
   # Multiple sorts are possible at any time, but it is up to the code to keep things straight.

   # Example: sort by highest effective scorei, decreasing.
   @{$population->{'people'}} = sort { $b->{'eMax'} <=> $a->{'eMax'} } @{$population->{'people'}};

   # Assign first n people to team 1, next n people to team 2, etc.
   for (my $team=0;$team<$teamsPerPopulation;$team++) {
      $teams[$team] = [];
      for (my $person=$team*$peoplePerTeam;$person<($team+1)*$peoplePerTeam;$person++) {
         # Optional, but highly recommended, is to record the assigned team as part of the 
         # person's record.  We assign $team + 1 so team numbers are in the more human-friendly
         # 1, 2, ..., n form.
         $population->{'people'}[$person]{'team'} = $team + 1;
         # Note we are pushing $person{'index'}, the fixed index field, onto the team array.
         # If you do this, you must also sort by index before returning, as shown below.
         push(@{$teams[$team]},${$population->{'people'}[$person]{'index'}});
      }
   }

   # Final ascending sort by index before returning, since we populated team arrays with index values.
   @{$population->{'people'}} = sort { $a->{'index'} <=> $b->{'index'} } @{$population->{'people'}};

###################################################################################
# End of user-defined code for populating @teams from @populations for this model
###################################################################################

   return @teams;
};
