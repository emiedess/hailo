use 5.10.0;
use strict;
use warnings;
use Test::More tests => 1;
use Hailo::UI::ReadLine;

my $readline = Hailo::UI::ReadLine->new;

is($ENV{PERL_RL}, 'Gnu', "Using Term::ReadLine::Gnu");