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

sub build_cards {
  return (
    MAJOR_ARCANA,
    (
      map {
        my $suit = $_;
        map { "$_ of $suit" } 1 .. 10, qw(page knight queen king)
      } MINOR_ARCANA_SUITS
    ),
  );
}

sub build_deck {
  my @cards = build_cards();
  my %deck;
  my $n = 0;
  for my $card (@cards) {
    $deck{$card} = {
      name   => $card,
      p      => $n, # position
      o      => 0,  # orientation
      chosen => 0,  # has been chosen
      file   => card_file($card),
    };
    $n++;
  }
  return \%deck;
}

sub shuffle_deck {
  my ($deck, $orient) = @_;
  my @shuffled = shuffle(keys %$deck);
  my $i = 0;
  for my $card (@shuffled) {
    my $orientation = $orient ? int rand 2 : $deck->{$card}{o};
    $deck->{$card}->{p} = $i;
    $deck->{$card}->{o} = $orientation;
    $i++;
  }
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
  my $i = 0;
  for my $card (@cut) {
    $deck->{$card}{p} = $i;
    $i++;
  }
}

sub choose {
  my ($deck, $n) = @_;
  $n //= int rand keys %$deck;
  my $chosen;
  for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
    next unless $deck->{$card}{p} == $n;
    $chosen = $card;
    last;
  }
  croak 'No card chosen' unless $chosen;
  $deck->{$chosen}{chosen} = 1;
  return $deck->{$chosen};
}

sub spread {
  my ($deck, $n) = @_;
  $n ||= 3;
  my @spread;
  for my $draw (1 .. $n) {
    my %non_chosen = map { $_ => $deck->{$_} } grep { $deck->{$_}{chosen} == 0 } keys %$deck;
    push @spread, choose(\%non_chosen);
  }
  return \@spread;
}

sub clear {
  my ($deck) = @_;
  for my $card (keys %$deck) {
    $deck->{$card}{chosen} = 0;
  }
}

sub card_file {
  my ($card) = @_;
  my $filename = '/images/' . $card . '.jpeg';
  return $filename;
}

1;
