#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Tarot';

my $d = Tarot::build_deck();

is @$d, 78, 'full deck';

my $expect = [qw(fool magician priestess empress emperor hierophant lovers chariot strength hermit)];
is_deeply [@$d[0 .. 9]], $expect, 'looks sorted';

$d = Tarot::shuffle_deck($d);

$d = Tarot::cut_deck($d, 1);

my $spread = Tarot::spread($d);

done_testing();
