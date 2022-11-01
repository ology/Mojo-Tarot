#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Set::Array;

use_ok 'Tarot';

my $deck;
my @cards;

subtest build_cards => sub {
  @cards = Tarot::build_cards();
  is @cards, 78, 'cards';
};

subtest build_deck => sub {
  ($deck) = Tarot::build_deck();
  is keys %$deck, @cards, 'full deck';

  my $i = 0;
  for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
    is $card, $cards[$i], $card;
    $i++;
  }
  diag 'If we got here ok, the deck is sorted';
};

subtest shuffle_deck => sub {
  my $is_shuffled = 0;
  my ($shuffled) = Tarot::shuffle_deck($deck);
  my $i = 0;
  for my $card (sort { $shuffled->{$a}{p} <=> $shuffled->{$b}{p} } keys %$shuffled) {
    $is_shuffled++ if $card ne $cards[$i];
    $i++;
  }
  ok $is_shuffled, 'is shuffled';

  subtest orientation => sub {
    my $is_oriented = 0;
    my ($oriented) = Tarot::shuffle_deck($deck, 1);
    for my $card (keys %$oriented) {
      $is_oriented++ if $oriented->{$card}{o};
    }
    ok $is_oriented, 'is oriented';
  };
};

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
