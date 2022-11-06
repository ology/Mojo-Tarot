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
    ->session_ok('/session')
    ->content_like(qr/Court de Gébelin/, 'has title')
    ->element_exists('button[value="view"]', 'has View btn')
    ->element_exists('button[value="reset"]', 'has Reset btn')
    ->element_exists('select[name="cut"]', 'has Cut select')
    ->element_exists('button[value="shuffle"]', 'has Shuffle btn')
    ->element_exists('input[type="checkbox"][name="orient"]', 'has Orient checkbox')
    ->element_exists('select[name="reading"]', 'has Load select')
    ->element_exists('select[name="type"]', 'has Spread select')
    ->element_exists('select[name="choice"]', 'has Choose select')
    ->element_exists('button[value="clear"]', 'has Clear btn')
  ;
};

subtest view => sub {
  $t->get_ok('/?action=view')
    ->status_is(200)
    ->element_count_is('img', 78, '78 images')
  ;
};

subtest reset => sub {
  $t->get_ok('/?action=reset')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->element_exists_not('img', 'image not on page')
  ;
  $t->get_ok('/?action=view')
    ->status_is(200)
    ->element_exists('img:nth-of-type(1)[alt="fool"]', 'fool card first')
    ->element_exists('img:nth-last-of-type(1)[alt="king of pentacles"]', 'king of pentacles card last')
  ;
};

subtest cut => sub {
  $t->get_ok('/?action=cut&cut=100')
    ->status_is(200)
    ->content_unlike(qr|Cut 100\s*</div>|, 'cut text')
  ;
  $t->get_ok('/?action=cut&cut=0')
    ->status_is(200)
    ->content_like(qr|Cut 0\s*</div>|, 'cut text')
  ;
  $t->get_ok('/?action=view')
    ->status_is(200)
    ->element_exists('img:nth-of-type(1)[alt="magician"]', 'magician card first')
    ->element_exists('img:nth-last-of-type(1)[alt="fool"]', 'fool card last')
  ;
};

subtest shuffle => sub {
  subtest nonoriented => sub {
    $t->get_ok('/?action=shuffle')
      ->status_is(200)
      ->content_like(qr|Shuffle\s*</div>|, 'shuffle text')
    ;
  };

  subtest oriented => sub {
    $t->get_ok('/?action=shuffle&orient=on')
      ->status_is(200)
    ;
    $t->get_ok('/?action=view')
      ->status_is(200)
      ->content_like(qr/style="transform: scaleY\(-1\);"/, 'orient on') # at least 1 card is flipped
    ;
  };
};

subtest spread => sub {
  $t->get_ok('/?action=spread&type=1')
    ->status_is(200)
    ->content_like(qr|Spread 1\s*</div>|, 'spread text')
    ->element_exists('img', 'image on page')
    ->element_exists('input[type="text"][name="name"]', 'has reading name input')
    ->element_exists('button[value="save"]', 'has Save btn')
  ;
  $t->get_ok('/?action=spread&type=100')
    ->status_is(200)
    ->content_like(qr|Spread 100\s*</div>|, 'spread text')
    ->element_count_is('img', 78, '78 images')
  ;
};

subtest choose => sub {
  $t->get_ok('/?action=reset')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->element_exists_not('img', 'image not on page')
  ;
  $t->get_ok('/?action=cut&cut=0') # NB: make sure the deck has been changed
    ->status_is(200)
    ->content_like(qr|Cut 0\s*</div>|, 'cut text')
  ;
  $t->get_ok('/?action=choose&choice=0')
    ->status_is(200)
    ->content_like(qr|Choose 0\s*</div>|, 'choose text')
    ->element_count_is('img', 1, '1 image only')
    ->element_exists('img[alt="magician"]', 'magician card')
    ->element_exists('input[type="text"][name="name"]', 'has reading name input')
    ->element_exists('button[value="save"]', 'has Save btn')
  ;
};

subtest clear => sub {
  $t->get_ok('/?action=clear')
    ->status_is(200)
    ->content_unlike(qr/<div class="small">/, 'no action text')
    ->element_exists_not('img', 'image not on page')
  ;
  $t->get_ok('/?action=view') # NB: make sure the cut deck is unchanged
    ->status_is(200)
    ->element_exists('img:nth-of-type(1)[alt="magician"]', 'magician card first')
  ;
};

subtest cleanup => sub {
  diag 'Clean-up the file(s) created by this test...';
  my @files = File::Find::Rule->file()->name($name)->in('.');
  for my $file (@files) {
    ok -e $file, "$file exists";
    unlink $file;
    ok !-e $file, 'removed deck file';
  }
};

done_testing();
