use Mojo::Base -strict;

use File::Find::Rule ();
use Time::HiRes qw(time);

use Test::Mojo::Session;
use Test::More;

use Mojo::File qw(curfile);
my $t = Test::Mojo::Session->new(curfile->dirname->sibling('mojotarot.pl'));

my $now = time();
(my $stamp = $now) =~ s/^(\d+)\.\d+/$1/;
my $name = 'deck-' . $stamp . '.*.dat';
diag "Created deck file glob: $name";

subtest widgets => sub {
  $t->get_ok('/')
    ->status_is(200)
    ->session_ok
    ->session_like('/session' => qr/^(\d+)\.\d+$/, 'session created')
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
};

subtest view => sub {
  $t->get_ok('/?action=View')
    ->status_is(200)
    ->content_like(qr/title="Fool \(0\)"/, 'Fool (0) card')
    ->content_like(qr/title="King of pentacles \(77\)"/, 'King of pentacles (77) card')
  ;
};

subtest reset => sub {
  $t->get_ok('/?action=Reset')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->content_unlike(qr/img src/, 'image not on page')
  ;
};

subtest cut => sub {
  $t->get_ok('/?action=Cut&cut=1')
    ->status_is(200)
    ->content_like(qr|Cut 1\s*</div>|, 'Cut text')
  ;
};

subtest shuffle => sub {
  subtest nonoriented => sub {
    $t->get_ok('/?action=Shuffle')
      ->status_is(200)
      ->content_like(qr|Shuffle\s*</div>|, 'Shuffle text')
      ->content_unlike(qr/checked/, 'Orient not checked')
    ;
  };

  subtest oriented => sub {
    $t->get_ok('/?action=Shuffle&orient=on')
      ->status_is(200)
      ->content_like(qr/checked/, 'Orient checked')
    ;
  };
};

subtest spread => sub {
  $t->get_ok('/?action=Spread&type=1')
    ->status_is(200)
    ->content_like(qr|Spread 1\s*</div>|, 'Spread text')
    ->content_like(qr/img src/, 'image on page')
    ->content_like(qr/name="name"/, 'Reading name input')
    ->content_like(qr/value="Save"/, 'has Save btn')
  ;
};

subtest choose => sub {
  $t->get_ok('/?action=Reset')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->content_unlike(qr/img src/, 'image not on page')
  ;
  $t->get_ok('/?action=Choose&choice=0')
    ->status_is(200)
    ->content_like(qr|Choose 0\s*</div>|, 'Choose text')
    ->content_like(qr/img src/, 'image on page')
    ->content_like(qr/title="Fool \(0\)"/, 'Fool (0) card')
    ->content_like(qr/name="name"/, 'Reading name input')
    ->content_like(qr/value="Save"/, 'has Save btn')
  ;
};

subtest clear => sub {
  $t->get_ok('/?action=Clear')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action trail')
    ->content_unlike(qr/img src/, 'image not on page')
  ;
};

subtest purge => sub {
  diag 'Purge the deck file(s) created by this test...';
  my @files = File::Find::Rule->file()->name($name)->in('.');
  for my $file (@files) {
    ok -e $file, "deck file: $file exists";
    unlink $file;
    ok !-e $file, 'removed deck file';
  }
};

done_testing();
