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
  is keys $deck->{cards}->%*, @cards, 'full deck';

  my $i = 0;
  for my $card (sort { $deck->{cards}{$a}{p} <=> $deck->{cards}{$b}{p} } keys $deck->{cards}->%*) {
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
    for my $card (sort { $deck->{cards}{$a}{p} <=> $deck->{cards}{$b}{p} } keys $deck->{cards}->%*) {
      $is_shuffled++ if $card ne $cards[$i];
      $is_oriented++ if $deck->{cards}{$card}{o};
      $i++;
    }
    ok $is_shuffled, 'is shuffled';
    ok !$is_oriented, 'is NOT oriented';
  };

  subtest orientation => sub {
    my $is_oriented = 0;
    Tarot::shuffle_deck($deck, 1);
    for my $card (keys $deck->{cards}->%*) {
      $is_oriented++ if $deck->{cards}{$card}{o};
    }
    ok $is_oriented, 'is oriented';
  };
};

subtest cut_deck => sub {
  my $sa = Set::Array->new(@cards);
  my @rotated = $sa->rotate('ftol');
  ($deck) = Tarot::build_deck();
  diag 'Cut deck at position 0';
  Tarot::cut_deck($deck, 0);
  my $i = 0;
  for my $card (sort { $deck->{cards}{$a}{p} <=> $deck->{cards}{$b}{p} } keys $deck->{cards}->%*) {
    is $card, $rotated[$i], $card;
    $i++;
  }
};

subtest choose => sub {
  ($deck) = Tarot::build_deck();
  diag 'Choose the card at position 0';
  my $expect = 'fool';
  my ($got) = Tarot::choose($deck, 0);
  is $got->{name}, $expect, 'expected card returned';
  my $chosen = 0;
  for my $card (keys $deck->{cards}->%*) {
    if ($deck->{cards}{$card}{chosen}) {
      $chosen++;
      is $deck->{cards}{$card}{name}, $expect, 'expected chosen in deck';
    }
  }
  is $chosen, 1, '1 card chosen';
};

subtest spread => sub {
  ($deck) = Tarot::build_deck();
  my $expect = 3;
  my ($got) = Tarot::spread($deck, $expect);
  is @$got, $expect, 'expected spread size';
  my $chosen = 0;
  for my $card (keys $deck->{cards}->%*) {
    $chosen++ if $deck->{cards}{$card}{chosen};
  }
  is $chosen, $expect, '3 cards chosen in deck';
};

done_testing();
