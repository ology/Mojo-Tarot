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
ok $d->[0] ne 'fool'
  && $d->[1] ne 'magician'
  && $d->[2] ne 'priestess'
  && $d->[3] ne 'empress'
  && $d->[4] ne 'emperor'
  && $d->[5] ne 'hierophant'
  && $d->[6] ne 'lovers'
  && $d->[7] ne 'chariot'
  && $d->[8] ne 'strength'
  && $d->[9] ne 'hermit', 'looks shuffled';

$expect = $d->[0];
$d = Tarot::cut_deck($d, 1);
is $d->[-1], $expect, 'cut deck';

my $spread = Tarot::spread($d);

done_testing();
