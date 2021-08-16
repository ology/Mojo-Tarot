#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Carp qw(croak);
use List::Util qw(shuffle);

use Tarot;

my $d = Tarot::build_deck();
#warn(__PACKAGE__,' ',__LINE__," MARK: ",scalar(@$d),' - ',ddc($d));

$d = Tarot::shuffle_deck($d);
#warn(__PACKAGE__,' ',__LINE__," MARK: ",scalar(@$d),' - ',ddc($d));

$d = Tarot::cut_deck($d, 1);
#warn(__PACKAGE__,' ',__LINE__," MARK: ",scalar(@$d),' - ',ddc($d));

my $spread = Tarot::spread($d);
warn(__PACKAGE__,' ',__LINE__," MARK: ",ddc($spread));
