#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Tarot';

my ($deck) = Tarot::build_deck();
is keys %$deck, 78, 'full deck';

my @expect = Tarot::build_cards();

my $i = 0;
for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
  is $card, $expect[$i], $card;
  $i++;
}
diag 'If we got here ok, the deck is sorted';

done_testing();

__END__
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
my $orientations = [];
($orientations, $d) = Tarot::cut_deck($orientations, $d, 1);
is $d->[-1], $expect, 'cut deck';

my $got = Tarot::spread($d, 3);
is @$got, 3, 'spread size';

$expect = [@$d[0 .. 2]];
$got = [Tarot::choose($d, 1)];
is @$got, 2, 'choose size';
is $got->[0], $expect->[0], 'choose';
$got = [Tarot::choose($d, 1)];
is $got->[0], $expect->[1], 'choose';
$got = [Tarot::choose($d, 1)];
is $got->[0], $expect->[2], 'choose';

done_testing();
