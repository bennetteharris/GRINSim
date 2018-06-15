push @populationTypes, 'Clone';

sub assignCloneResources {
   # Assign all $resourceUnitsPerPerson to the "H" (hermaphrodite) category.
   my %resources;
   foreach my $category (@categoryTypes) {
      $resources{$category} = 0;
   }
   $resources{"H"} = $resourceUnitsPerPerson;
   return %resources;
}
