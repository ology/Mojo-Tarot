package Tarot;

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
  my @deck = (
    MAJOR_ARCANA,
    (
      map {
        my $suit = $_;
        map { "$_ of $suit" } 1 .. 10, qw(page knight queen king)
      } MINOR_ARCANA_SUITS
    ),
  );
  return \@deck;
}

sub shuffle_deck {
  my $deck = shift;
  $deck = [ shuffle(@$deck) ];
  return $deck;
}

sub cut_deck {
  my ($deck, $n) = @_;
  $n ||= int @$deck / 2;
  croak "N must be between 1 and ", scalar(@$deck), "\n"
    if $n > @$deck || $n < 1;
  $deck = [
    @$deck[ $n .. $#$deck ],
    @$deck[ 0 .. $n - 1 ],
  ];
  return $deck;
}

sub choose {
  my ($deck, $n) = @_;
  if ($n) {
    $n -= 1;
  }
  else {
    $n = int rand @$deck;
  }
  my $card = $deck->[$n];
  # Remove the card from the deck
  splice @$deck, $n, 1;
  my $orientation = int rand 2;
  my $filename = card_file($card);
  return $card, $orientation, $filename;
}

sub spread {
  my ($deck, $n) = @_;
  $n ||= 3;
  my @spread;
  for my $draw (1 .. $n) {
    push @spread, [ choose($deck) ];
  }
  return \@spread;
}

sub card_file {
  my ($card) = @_;
  my $filename = '/images/' . $card . '.jpeg';
  return $filename;
}

1;
