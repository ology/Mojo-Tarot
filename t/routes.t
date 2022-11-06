use Mojo::Base -strict;

use File::Find::Rule ();
use Mojo::File qw(curfile);
use Time::HiRes qw(time);

use Test::Mojo::Session;
use Test::More;

my $t = Test::Mojo::Session->new(curfile->dirname->sibling('mojotarot.pl'));

my $now = time();
(my $stamp = $now) =~ s/^(\d+)\.\d+/$1/;
my $name = 'deck-' . $stamp . '.*.dat';
diag "Created deck file glob: $name";

subtest widgets => sub {
  $t->get_ok('/')
    ->status_is(200)
    ->session_like('/session' => qr/^$stamp\.\d+$/, 'session created')
    ->content_like(qr/Court de Gébelin/, 'has title')
    ->content_like(qr/value="view"/, 'has View btn')
    ->content_like(qr/value="reset"/, 'has Reset btn')
    ->content_like(qr/value="cut"/, 'has Cut select')
    ->content_like(qr/value="shuffle"/, 'has Shuffle btn')
    ->content_like(qr/name="orient"/, 'has Orient checkbox')
    ->content_like(qr/name="reading"/, 'has Load select')
    ->content_like(qr/value="spread"/, 'has Spread select')
    ->content_like(qr/value="choose"/, 'has Choose select')
    ->content_like(qr/value="clear"/, 'has Clear btn')
  ;
};

subtest view => sub {
  $t->get_ok('/?action=view')
    ->status_is(200)
    ->content_like(qr/title="Fool \(0\)"/, 'Fool (0) card')
    ->content_like(qr/title="King of pentacles \(77\)"/, 'King of pentacles (77) card')
  ;
};

subtest reset => sub {
  $t->get_ok('/?action=reset')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->content_unlike(qr/img src/, 'image not on page')
  ;
};

subtest cut => sub {
  $t->get_ok('/?action=cut&cut=1')
    ->status_is(200)
    ->content_like(qr|Cut 1\s*</div>|, 'Cut text')
  ;
};

subtest shuffle => sub {
  subtest nonoriented => sub {
    $t->get_ok('/?action=shuffle')
      ->status_is(200)
      ->content_like(qr|Shuffle\s*</div>|, 'Shuffle text')
      ->content_unlike(qr/checked/, 'Orient not checked')
    ;
  };

  subtest oriented => sub {
    $t->get_ok('/?action=shuffle&orient=on')
      ->status_is(200)
      ->content_like(qr/checked/, 'Orient checked')
    ;
  };
};

subtest spread => sub {
  $t->get_ok('/?action=spread&type=1')
    ->status_is(200)
    ->content_like(qr|Spread 1\s*</div>|, 'Spread text')
    ->content_like(qr/img src/, 'image on page')
    ->content_like(qr/name="name"/, 'Reading name input')
    ->content_like(qr/value="save"/, 'has Save btn')
  ;
};

subtest choose => sub {
  $t->get_ok('/?action=reset')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->content_unlike(qr/img src/, 'image not on page')
  ;
  $t->get_ok('/?action=choose&choice=0')
    ->status_is(200)
    ->content_like(qr|Choose 0\s*</div>|, 'Choose text')
    ->content_like(qr/img src/, 'image on page')
    ->content_like(qr/title="Fool \(0\)"/, 'Fool (0) card')
    ->content_like(qr/name="name"/, 'Reading name input')
    ->content_like(qr/value="save"/, 'has Save btn')
  ;
};

subtest clear => sub {
  $t->get_ok('/?action=clear')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action trail')
    ->content_unlike(qr/img src/, 'image not on page')
  ;
};

subtest purge => sub {
  diag 'Purge the deck file(s) created by this test...';
  my @files = File::Find::Rule->file()->name($name)->in('.');
  for my $file (@files) {
    ok -e $file, "$file exists";
    unlink $file;
    ok !-e $file, 'removed deck file';
  }
};

done_testing();
