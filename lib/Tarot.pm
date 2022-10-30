package Tarot;

use strict;
use warnings;

use Data::Dumper::Compact qw(ddc);
use Carp qw(croak);
use List::Util qw(shuffle);

use constant MAJOR_ARCANA => (
  'fool',
  'magician',
  'priestess',
  'empress',
  'emperor',
  'hierophant',
  'lovers',
  'chariot',
  'strength',
  'hermit',
  'wheel of fortune',
  'justice',
  'hanged man',
  'death',
  'temperance',
  'devil',
  'tower',
  'star',
  'moon',
  'sun',
  'judgment',
  'world',
);
use constant MINOR_ARCANA_SUITS => (
  'wands',
  'cups',
  'swords',
  'pentacles',
);

sub build_deck {
  my @cards = (
    MAJOR_ARCANA,
    (
      map {
        my $suit = $_;
        map { "$_ of $suit" } 1 .. 10, qw(page knight queen king)
      } MINOR_ARCANA_SUITS
    ),
  );
  my %deck;
  my $n = 0;
  for my $card (@cards) {
    $n++;
    $deck{$card} = {
      name   => $card,
      p      => $n, # position
      o      => 0,  # orientation
      chosen => 0,
      file   => card_file($card),
    };
  }
  return \%deck;
}

sub shuffle_deck {
  my ($deck, $orient) = @_;
  my @shuffled = shuffle(keys %$deck);
  my $shuffled_deck = { %$deck };
  my $i = 0;
  for my $card (@shuffled) {
    $i++;
    my $orientation = $orient ? int rand 2 : $deck->{$card}{o};
    $shuffled_deck->{$card}{p} = $i;
    $shuffled_deck->{$card}{o} = $orientation;
  }
  return $shuffled_deck;
}

sub cut_deck {
  my ($deck, $n) = @_;
  my @cards = keys %$deck;
  $n ||= int(@cards) / 2; # default half of deck
  croak "N must be between 1 and ", scalar(@cards), "\n"
    if $n < 1 || $n > @cards;
  my @ordered = sort { $deck->{$a}{p} <=> $deck->{$b}{p} } @cards;
  my @cut = (
    @ordered[ $n .. $#ordered ],
    @ordered[  0 .. $n - 1 ],
  );
  my $cut_deck = { %$deck };
  my $i = 0;
  for my $card (@cut) {
    $i++;
    $cut_deck->{$card}{p} = $i;
  }
  return $cut_deck;
}

sub choose {
  my ($deck, $n) = @_;
  $n ||= int rand keys %$deck;
  my %not_chosen = %$deck;
  my $i = 0;
  for my $card (sort { $not_chosen{$a}{p} <=> $not_chosen{$b}{p} } keys %not_chosen) {
    next if $not_chosen{$card}{chosen};
    $i++;
    $not_chosen{$card} = $deck->{$card};
    $not_chosen{$card}{p} = $i;
  }
  my $chosen;
  for my $card (keys %not_chosen) {
    if ($not_chosen{$card}{p} == $n) {
      $chosen = $card;
      last;
    }
  }
  croak 'No card chosen' unless $chosen;
  my $filename = card_file($chosen);
  $deck->{$chosen}{chosen} = 1;
  return $deck->{$chosen};
}

sub spread {
  my ($deck, $n) = @_;
  $n ||= 3;
  my @spread;
  for my $draw (1 .. $n) {
    push @spread, choose($deck);
  }
  return \@spread;
}

sub card_file {
  my ($card) = @_;
  my $filename = '/images/' . $card . '.jpeg';
  return $filename;
}

1;
