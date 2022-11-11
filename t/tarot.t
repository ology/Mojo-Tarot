#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Set::Array;

use_ok 'Tarot';

my $deck;
my @cards;

sub _sorted_keys {
  my ($deck) = @_;
  return sort { $deck->{cards}{$a}{p} <=> $deck->{cards}{$b}{p} }
    keys $deck->{cards}->%*;
}

subtest build_cards => sub {
  @cards = Tarot::build_cards();
  is @cards, 78, 'cards';
};

subtest build_deck => sub {
  ($deck) = Tarot::build_deck();
  is keys $deck->{cards}->%*, @cards, 'full deck';

  my $i = 0;
  for my $card (_sorted_keys($deck)) {
    is $card, $cards[$i], $card;
    $i++;
  }
  diag 'If still ok, deck is sorted';
};

subtest shuffle_deck => sub {
  subtest nonoriented => sub {
    my $is_shuffled = 0;
    my $is_oriented = 0;
    Tarot::shuffle_deck($deck);
    my $i = 0;
    for my $card (_sorted_keys($deck)) {
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
  for my $card (_sorted_keys($deck)) {
    is $card, $rotated[$i], $card;
    $i++;
  }
};

subtest choose => sub {
  ($deck) = Tarot::build_deck();
  my $expect = 'fool';
  diag 'Choose the card at position 0';
  my ($got) = Tarot::choose($deck, 0);
  is $got->{name}, $expect, 'expected card returned';
  my $chosen = 0;
  my @names;
  for my $card (keys $deck->{cards}->%*) {
    if ($deck->{cards}{$card}{chosen}) {
      $chosen++;
      push @names, $card;
    }
  }
  is $chosen, 1, '1 card chosen in deck';
  is $got->{name}, $names[0], 'expected card chosen in deck';
};

subtest spread => sub {
  ($deck) = Tarot::build_deck();
  my $expect = 3;
  diag "Choose a spread of $expect cards";
  my ($got) = Tarot::spread($deck, $expect);
  is @$got, $expect, 'expected spread size';
  my $chosen = 0;
  my @names;
  for my $card (keys $deck->{cards}->%*) {
    if ($deck->{cards}{$card}{chosen}) {
      $chosen++;
      push @names, $card;
    }
  }
  is $chosen, $expect, "$expect cards chosen in deck";
  is_deeply [ sort map { $_->{name} } @$got ], [ sort @names ],
    'expected cards chosen in deck';
};

subtest get_chosen => sub {
  ($deck) = Tarot::build_deck();
  my $choose = [];
  my $expect = [];
  my ($got) = Tarot::get_chosen($deck, $choose);
  is_deeply $got, $expect, 'no choices';
  $choose = [666, 667];
  ($got) = Tarot::get_chosen($deck, $choose);
  is_deeply $got, $expect, 'invalid choices';
  $choose = [13, 1, 0];
  $expect = [
    { chosen => 0, file => '/images/death.jpeg', n => 13, name => 'death', o => 0, p => 13 },
    { chosen => 0, file => '/images/magician.jpeg', n => 1, name => 'magician', o => 0, p => 1 },
    { chosen => 0, file => '/images/fool.jpeg', n => 0, name => 'fool', o => 0, p => 0 },
  ];
  ($got) = Tarot::get_chosen($deck, $choose);
  is_deeply $got, $expect, 'valid choices';
};

done_testing();
