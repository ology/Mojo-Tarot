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

my $is_shuffled = 0;
my ($shuffled) = Tarot::shuffle_deck($deck);
$i = 0;
for my $card (sort { $shuffled->{$a}{p} <=> $shuffled->{$b}{p} } keys %$shuffled) {
  $is_shuffled++ if $card ne $expect[$i];
  $i++;
}
ok $is_shuffled, 'shuffle';

done_testing();

__END__
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
