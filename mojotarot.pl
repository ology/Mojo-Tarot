#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper::Compact qw(ddc);
use File::Find::Rule ();
use List::Util qw(first);
use Storable qw(retrieve store);
use Time::HiRes qw(time);

use lib 'lib';
use Tarot ();

use constant DECK_GLOB    => 'deck-*.dat';
use constant READING_GLOB => 'reading-*.dat';
use constant TIME_LIMIT   => 60 * 60 * 24; # 1 day

get '/' => sub ($c) {
  my $type   = $c->param('type');         # spread type
  my $cut    = $c->param('cut');          # cut deck
  my $action = $c->param('action') || ''; # action to perform
  my $choice = $c->param('choice');       # chosen card
  my $orient = $c->param('orient') || 0;  # shuffle upside down
  my $save   = $c->param('name');         # saved reading name
  my $load   = $c->param('reading');      # reading to load

  # is there a deck to use?
  my $deck; # NB: this variable is roughly immortal, and continuously changing
  my $session = $c->session('session') || '';
  my $session_file = _make_save_file($session);
  if ($session && -e $session_file) {
    $deck = retrieve $session_file;
    $c->app->log->info("Loaded session deck $session");
  }
  else {
    ($deck, $session) = _store_deck($c);
    $c->app->log->info("Made new session deck $session");
  }

  _purge($c); # purge old decks & readings

  # collect the 0-77 choices that have been made
  my $choices = $c->cookie('choice') // '';
  $choices = [ split /\|/, $choices ];

  # collect the actions taken
  my $crumbs = $c->cookie('crumbs') || '';
  $crumbs = [ split /\|/, $crumbs ];

  my $view = 0; # viewing is off by default

  # take action!
  if ($action eq 'view') {
    $view = 1;
  }
  elsif ($action eq 'shuffle') {
    Tarot::shuffle_deck($deck, $orient);
    push @$crumbs, _make_crumb($action);
  }
  elsif ($action eq 'cut') {
    Tarot::cut_deck($deck, $cut);
    push @$crumbs, _make_crumb($action, $cut);
  }
  elsif ($action eq 'reset') {
    ($deck) = Tarot::build_deck();
    $choices = [];
    $crumbs = [];
  }
  elsif ($action eq 'spread') {
    my ($spread) = Tarot::spread($deck, $type);
    if (@$spread) {
      push @$choices, map { $_->{p} } @$spread;
      push @$crumbs, _make_crumb($action, $type);
    }
  }
  elsif ($action eq 'choose') {
    if (my ($card) = Tarot::choose($deck, $choice)) {
      push @$choices, $choice;
      push @$crumbs, _make_crumb($action, $choice);
    }
  }
  elsif ($action eq 'clear') {
    Tarot::clear($deck);
    $choices = [];
    $crumbs = [];
  }

  # remember the deck
  _store_deck($c, $deck, $session);

  # get the cards that have been chosen
  my @choices;
  for my $n (@$choices) {
    my $card = ( first { $deck->{cards}{$_}{p} == $n } keys $deck->{cards}->%* )[0];
    push @choices, $deck->{cards}{$card};
  }

  # save or load readings
  if ($action eq 'save') {
    my $reading = {
      session => $session,
      name    => $save,
      choices => \@choices,
    };
    my $file = _make_save_file($session, 'reading');
    store($reading, $file);
  }
  elsif ($action eq 'load') {
    my $data = retrieve $load;
    @choices = $data->{choices}->@*;
    $choices = [ map { $_->{p} } @choices ];
    $crumbs = [ _make_crumb($action, $data->{name}) ];
  }

  # load the session reading file form options
  my @readings;
  my @files = File::Find::Rule->file()->name(READING_GLOB)->in('.');
  for my $file (sort @files) {
    my $reading = retrieve $file;
    push @readings, { file => $file, name => $reading->{name} }
      if $reading->{session} == $session;
  }

  # remember the choices and actions
  $c->cookie(choice => join('|', @$choices), { samesite => 'Lax' });
  $c->cookie(crumbs => join('|', @$crumbs), { samesite => 'Lax' });

  $c->render(
    template => 'index',
    deck     => $deck,
    view     => $view,
    choices  => \@choices,
    crumbs   => $crumbs,
    readings => \@readings,
  );
} => 'index';

app->log->level('info');

app->start;

sub _purge {
  my ($c) = @_;
  my $now = time();
  (my $stamp = $now) =~ s/^(\d+)\.\d+/$1/;
  my @files = File::Find::Rule->file()->name(DECK_GLOB)->in('.');
  my $purged = 0;
  for my $file (sort @files) {
    my $deck = retrieve $file;
    if ($deck->{last_seen} + TIME_LIMIT < $now) {
      $c->app->log->info("Removing $file deck");
      $purged++;
    }
  }
  # TODO purge readings too
}

sub _make_crumb {
  my ($action, $datum) = @_;
  my $crumb = ucfirst $action;
  $crumb .= ' ' . $datum if defined $datum;
  return $crumb;
}

sub _make_save_file {
  my ($session, $type) = @_;
  $type ||= 'deck';
  my $file = sprintf './%s-%s.dat', $type, $session;
  return $file;
}

sub _store_deck {
  my ($c, $deck, $session) = @_;
  ($deck) ||= Tarot::build_deck();
  unless ($session) {
    $session = time();
    $c->session(session => $session, expiration => TIME_LIMIT);
  }
  my $file = _make_save_file($session);
  $deck->{last_seen} = time();
  store($deck, $file);
  return $deck, $c->session('session');
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Court de Gébelin';

<div>

% # View
<form method="get" class="block">
  <button type="submit" name="action" title="View the deck" value="view" class="btn btn-sm btn-success" />
    View
  </button>
</form>

% # Reset
<form method="get" class="block">
  <button type="submit" name="action" title="Reset the deck" value="reset" class="btn btn-sm btn-info" />
    Reset
  </button>
</form>

% # Cut
<form method="get" class="block">
  <input type="hidden" name="action" value="cut" />
  <select name="cut" title="Cut the deck" class="btn btn-sm" onchange="this.form.submit()">
    <option value="0" selected disabled>Cut</option>
% for my $n (0 .. keys($deck->{cards}->%*) - 2) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>

% # Shuffle
<form method="get" class="block">
  <button type="submit" name="action" title="Shuffle the deck" value="shuffle" class="btn btn-sm btn-info" />
    Shuffle
  </button>
  <div class="form-check form-check-inline">
    <input class="form-check-input" type="checkbox" name="orient" title="Shuffle with approximately half upside down" />
  </div>
</form>

<p></p>

% # Spread
<form method="get" class="block">
  <input type="hidden" name="action" value="spread" />
  <select name="type" title="Generate a spread" onchange="this.form.submit()" class="btn btn-sm">
    <option value="0" selected disabled>Spread</option>
% for my $n (1 .. 12) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>

% # Choose
<form method="get" class="block">
  <input type="hidden" name="action" value="choose" />
  <select name="choice" title="Choose a card" class="btn btn-sm" onchange="this.form.submit()">
    <option value="" selected disabled>Card</option>
% for my $card (sort { $deck->{cards}{$a}{p} <=> $deck->{cards}{$b}{p} } keys $deck->{cards}->%*) {
%   my $n = $deck->{cards}{$card}{p};
%   my $disabled = $deck->{cards}{$card}{chosen} ? 'disabled' : '';
    <option value="<%= $n %>" <%= $disabled %>><%= $n %></option>
% }
  </select>
</form>

% # Clear
<form method="get" class="block">
  <button type="submit" name="action" title="Clear the choices" value="clear" class="btn btn-sm btn-light" />
    Clear
  </button>
</form>

<p></p>

% # Load
<form method="get" class="block">
  <input type="hidden" name="action" value="load" />
  <select name="reading" title="Choose a reading" class="btn btn-sm" onchange="this.form.submit()">
    <option value="" selected disabled>Load Reading</option>
% for my $reading (@$readings) {
    <option value="<%= $reading->{file} %>"><%= $reading->{name} %></option>
% }
  </select>
</form>

</div>

<p></p>

% if (@$crumbs) {
<div class="small">
  <%= join ' > ', @$crumbs %>
</div>
% }

% if (@$choices) {
<hr>
<div>
%   for my $card (@$choices) {
%     my $style = $card->{o} ? 'transform: scaleY(-1);' : '';
  <a href="<%= $card->{file} %>">
  <img src="<%= $card->{file} %>" alt="<%= $card->{name} %>" title="<%= ucfirst $card->{name} %> (<%= $card->{n} %>)" height="200" width="100" style="<%= $style %>" />
  </a>
%   }
  <p></p>
  <form method="get" class="block">
    <input type="text" name="name" title="Name for this saved reading" placeholder="Reading name" />
    <button type="submit" name="action" title="Save this reading" value="save" class="btn btn-sm btn-dark" />
      Save
    </button>
  </form>
</div>
% }
% elsif ($view) {
<hr>
<div>
  <table cellpadding="2" border="0">
%   my $n = 0;
%   my $cells = 3;
%   for my $name (sort { $deck->{cards}{$a}{p} <=> $deck->{cards}{$b}{p} } keys $deck->{cards}->%*) {
%     my $card = $deck->{cards}{$name};
%     my $row = 0;
%     if ($n == 0 || $n % $cells == 0) {
    <tr>
%     }
      <td>
%       my $style = $card->{o} ? 'transform: scaleY(-1);' : '';
        <a href="<%= $card->{file} %>">
        <img src="<%= $card->{file} %>" alt="<%= $name %>" title="<%= ucfirst $name %> (<%= $card->{n} %>)" height="200" width="100" style="<%= $style %>" />
        </a>
      </td>
%     if ($row == $cells - 1) {
%     $row = 0;
    </tr>
%     } else {
%       $row++;
%     }
%     $n++;
%   }
  </table>
</div>
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous" onerror="this.onerror=null;this.href='/css/bootstrap.min.css';" />
    <title><%= title %></title>
    <style>
      body {
        font-family: luminari, fantasy;
      }
      .padpage {
        padding-top: 10px;
      }
      .block {
        display: inline-block;
      }
      .small {
        font-size: small;
        color: darkgrey;
      }
    </style>
  </head>
  <body>
    <div class="container padpage">
      <h3><%= title %></h3>
      <%= content %>
      <p></p>
      <div id="footer" class="small">
        <hr>
        Built by <a href="http://gene.ology.net/">Gene</a>
        with <a href="https://www.perl.org/">Perl</a> and
        <a href="https://mojolicious.org/">Mojolicious</a>
      </div>
    </div>
  </body>
</html>
