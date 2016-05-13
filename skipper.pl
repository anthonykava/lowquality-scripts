#!/usr/bin/perl -w
# vim: set ts=4 sw=4 set noet
#
# skipper.pl --	reads STDIN, skips lines, prints lines, start point can
#				be offset by a number of lines
#				e.g., ./skipper.pl 100 20 -2 < file.txt
#				@anthonykava

use strict;
use warnings;

my $skip=shift()||die("\nUsage: $0 numOfLinesToSkip [numOfLinesToPrint] [offsetStartLines]\n\n");
my $lines=shift()||0;	# number of lines to print
my $offset=shift()||0;	# offset start point by number of lines (can be signed)
while(<>)
{
	print() if $skip--<2-$offset;
	last() if $skip-2<$lines*-1;
}
