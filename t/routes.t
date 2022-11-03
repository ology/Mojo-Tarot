use Mojo::Base -strict;

use File::Find::Rule ();
use Time::HiRes qw(time);

use Test::Mojo;
use Test::More;

use Mojo::File qw(curfile);
my $t = Test::Mojo->new(curfile->dirname->sibling('mojotarot.pl'));

my $now = time();
(my $stamp = $now) =~ s/^(\d+)\.\d+/$1/;
my $name = 'deck-' . $stamp . '.*.dat';
diag "Created deck file glob: $name";

$t->get_ok('/')
  ->status_is(200)
  ->content_like(qr/Court de Gébelin/, 'has title')
  ->content_like(qr/value="View"/, 'has View btn')
  ->content_like(qr/value="Reset"/, 'has Reset btn')
  ->content_like(qr/value="Cut"/, 'has Cut select')
  ->content_like(qr/value="Shuffle"/, 'has Shuffle btn')
  ->content_like(qr/name="orient"/, 'has Orient checkbox')
  ->content_like(qr/name="reading"/, 'has Load select')
  ->content_like(qr/value="Spread"/, 'has Spread select')
  ->content_like(qr/value="Choose"/, 'has Choose select')
  ->content_like(qr/value="Clear"/, 'has Clear btn')
;

$t->get_ok('/?action=View')
  ->status_is(200)
  ->content_like(qr/title="Fool \(0\)"/, 'Fool (0) card')
  ->content_like(qr/title="King of pentacles \(77\)"/, 'King of pentacles (77) card')
;

$t->get_ok('/?action=Reset')
  ->status_is(200)
  ->content_like(qr|<div class="small">\s*Reset\s*</div>|, 'Reset text')
;

$t->get_ok('/?action=Cut&cut=1')
  ->status_is(200)
  ->content_like(qr|&gt; Cut 1\s*</div>|, 'Cut text')
;

$t->get_ok('/?action=Shuffle')
  ->status_is(200)
  ->content_like(qr|&gt; Shuffle\s*</div>|, 'Shuffle text')
  ->content_unlike(qr/checked/, 'Orient not checked')
;

$t->get_ok('/?action=Shuffle&orient=on')
  ->status_is(200)
  ->content_like(qr/checked/, 'Orient checked')
;

# purge the deck file(s) created by this test
my @files = File::Find::Rule->file()->name($name)->in('.');
for my $file (@files) {
  ok -e $file, "deck file: $file exists";
  unlink $file;
  ok !-e $file, 'removed deck file';
}

done_testing();
