#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Tarot';

my $d = Tarot::build_deck();
is @$d, 78, 'full deck';

my $expect = [qw(fool magician priestess empress emperor hierophant lovers chariot strength hermit)];
is_deeply [@$d[0 .. $#$expect]], $expect, 'looks sorted';

$d = Tarot::shuffle_deck($d);
ok $d->[0] ne $expect->[0]
  && $d->[1] ne $expect->[1]
  && $d->[2] ne $expect->[2]
  && $d->[3] ne $expect->[3]
  && $d->[4] ne $expect->[4]
  && $d->[5] ne $expect->[5]
  && $d->[6] ne $expect->[6]
  && $d->[7] ne $expect->[7]
  && $d->[8] ne $expect->[8]
  && $d->[9] ne $expect->[9], 'looks shuffled';

$expect = $d->[0];
$d = Tarot::cut_deck($d, 1);
is $d->[-1], $expect, 'cut deck';

my $spread = Tarot::spread($d, 3);
is @$spread, 3, 'spread size';

done_testing();
