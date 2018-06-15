   if ($fixedData) {
      my @data = qw(0	0	8	1	1
0	2	4	1	0
0	2	9	9	2
0	5	1	0	0
4	0	0	2	3
2	2	8	10	3
0	0	0	0	1
1	1	3	3	3
6	2	0	0	9
0	0	0	10	3
2	3	6	2	11
0	2	9	14	0
0	2	0	0	1
0	0	0	0	0
2	2	0	0	0
1	1	2	1	0
1	5	3	0	3
0	15	5	0	0
0	0	0	3	0
0	0	4	4	1
16	3	0	0	4
1	0	0	4	2
16	0	0	0	0
0	0	1	0	0
5	2	0	15	1
1	18	2	3	0
1	0	0	0	0
11	3	1	0	2
0	0	0	8	5
6	2	2	2	6
0	23	2	0	0
0	0	8	0	0
1	6	1	5	8
9	0	0	0	9
0	0	0	0	0
21	0	0	0	0
0	0	21	1	0
2	7	0	0	0
9	0	8	1	1
2	5	0	1	8
1	1	1	0	2
0	0	0	0	0
2	1	8	1	3
3	0	0	0	0
3	3	2	0	5
1	0	0	0	0
4	1	1	4	10
0	0	0	1	0
9	1	0	2	4
25	0	0	0	0
3	17	5	0	0
2	0	13	3	0
7	4	0	0	0
1	0	12	0	0
0	1	11	0	2
0	6	12	2	1
0	1	0	0	0
0	0	0	14	1
0	0	1	3	0
0	1	1	0	0
9	0	0	0	4
6	0	0	7	0
0	0	0	11	2
0	7	2	2	2
0	0	0	0	13
2	0	4	7	0
1	1	0	7	4
0	0	1	1	11
2	1	4	6	0
3	7	0	3	0
5	1	0	5	2
2	1	9	0	1
1	0	1	10	1
3	2	0	4	4
12	0	0	1	0
11	0	1	1	0
6	0	0	0	7
1	4	0	1	7
0	0	2	11	0
1	0	0	0	12
10	0	1	1	1
0	13	0	0	0
2	1	0	1	9
0	0	11	2	0
0	1	6	4	2
10	2	0	1	0
0	0	10	1	2
4	1	0	0	8
1	1	0	4	7
0	0	13	0	0
1	0	0	0	12
1	6	1	3	2
2	4	0	0	7
3	1	0	8	1
4	7	0	2	0
0	1	12	0	0
4	1	0	6	2
4	9	0	0	0
0	3	5	2	3
8	1	1	0	3
3	2	8	0	0
1	7	3	2	0
2	4	3	1	3
2	0	6	0	5
0	1	6	5	1
0	0	0	0	13
2	0	0	0	11
0	0	2	7	4
0	0	5	7	1
1	4	4	4	0
13	0	0	0	0
1	3	0	1	8
6	0	0	7	0
0	3	4	0	6
0	11	1	1	0
0	0	9	4	0
0	7	3	3	0
2	1	1	3	6
1	1	5	3	3
2	0	0	2	9
);
      my %resources;
      for (my $i=0;$i<60;$i++) {
         %resources = ( 'G'=>shift(@data),'R'=>shift(@data),'I'=>shift(@data),'N'=>shift(@data),'H'=>shift(@data) );
         $populations{'Unequal'}{"people"}[$i] = { assignEffectiveResources( %resources ) };
      }
      for (my $i=0;$i<60;$i++) {
         %resources = ( 'G'=>shift(@data),'R'=>shift(@data),'I'=>shift(@data),'N'=>shift(@data),'H'=>shift(@data) );
         $populations{'Equal'}{"people"}[$i] = { assignEffectiveResources( %resources ) };
      }
   }
1;