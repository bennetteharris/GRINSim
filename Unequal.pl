push @populationTypes, 'Unequal';

sub assignUnequalResources {
   # Assign a random amount of resources, from $minResourceUnitsPerPerson
   # up to $maxResourceUnitsPerPerson, randomly among all categories.
   # We do this by assigning each unit, one by one, to a random category.
   # This is inefficient, but clearly mathematically fair.
   my %resources;
   foreach my $category (@categoryTypes) {
      $resources{$category} = 0;
   }
   # determine resources for this person
   my $totalResources = int (rand $maxResourceUnitsPerPerson - $minResourceUnitsPerPerson + 1) + $minResourceUnitsPerPerson;
   # assign those resources randomly
   for (my $i=1;$i<=$totalResources;$i++) {
      # Assign resource unit $i to a random category
      my $category = $categoryTypes[ int (rand scalar(@categoryTypes)) ];
      $resources{$category}++;
   }
   %resources = assignRandom($totalResources);
   return %resources;
}
