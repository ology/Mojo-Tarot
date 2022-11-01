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
  subtest nonoriented => sub {
    my $is_shuffled = 0;
    my $is_oriented = 0;
    Tarot::shuffle_deck($deck);
    my $i = 0;
    for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
      $is_shuffled++ if $card ne $cards[$i];
      $is_oriented++ if $deck->{$card}{o};
      $i++;
    }
    ok $is_shuffled, 'is shuffled';
    ok !$is_oriented, 'is NOT oriented';
  };

  subtest orientation => sub {
    my $is_oriented = 0;
    Tarot::shuffle_deck($deck, 1);
    for my $card (keys %$deck) {
      $is_oriented++ if $deck->{$card}{o};
    }
    ok $is_oriented, 'is oriented';
  };
};

subtest cut_deck => sub {
  my $sa = Set::Array->new(@cards);
  my @rotated = $sa->rotate('ftol');
  ($deck) = Tarot::build_deck();
  diag 'Cut deck at position 1';
  Tarot::cut_deck($deck, 1);
  my $i = 0;
  for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
    is $card, $rotated[$i], $card;
    $i++;
  }
};

done_testing();
