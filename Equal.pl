push @populationTypes, 'Equal';

sub assignEqualResources {
   # Assign all $resourceUnitsPerPerson randomly among all categories.
   # We do this by assigning each unit, one by one, to a random category.
   # This is inefficient, but clearly mathematically fair.
   my %resources;
   foreach my $category (@categoryTypes) {
      $resources{$category} = 0;
   }
   # assign resources randomly
#   for (my $i=1;$i<=$resourceUnitsPerPerson;$i++) {
#      # Assign resource unit $i to a random category
#      my $category = $categoryTypes[ int (rand scalar(@categoryTypes)) ];
#      $resources{$category}++;
#   }
   %resources = assignRandom($resourceUnitsPerPerson);
   return %resources;
}
