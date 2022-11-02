#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper::Compact qw(ddc);
use Storable qw(retrieve store);

use lib 'lib';
use Tarot ();

# TODO Purge old session decks

get '/' => sub ($c) {
  my $type   = $c->param('type');         # spread type
  my $cut    = $c->param('cut');          # cut deck
  my $action = $c->param('action') || ''; # action to perform
  my $choice = $c->param('choice');       # chosen card
  my $orient = $c->param('orient') || 0;  # upside down or not?

  # is there a deck to use?
  my $deck;
  my $session = $c->session('session') || '';
  my $session_file = './deck-' . $session . '.dat';
  if ($session && -e $session_file) {
    $deck = retrieve $session_file;
  }
  else {
    $session = _store_deck($c);
    $c->app->log->info("Made new session deck $session");
  }

  # collect the choices 0-78 that have been made
  my $choices = $c->cookie('choice') // '';
  $choices = [ split /\|/, $choices ];

  # remember the actions taken
  my $crumb_trail = $c->cookie('crumbs') || '';
  $crumb_trail = [ split /\|/, $crumb_trail ];

  my $view = 0;

  # take action!
  if ($action eq 'View') {
    $view = 1;
  }
  elsif ($action eq 'Shuffle') {
    Tarot::shuffle_deck($deck, $orient);
    push @$crumb_trail, $action;
    $view = 1;
  }
  elsif ($action eq 'Cut') {
    Tarot::cut_deck($deck, $cut);
    push @$crumb_trail, "$action $cut";
  }
  elsif ($action eq 'Spread') {
    my ($spread) = Tarot::spread($deck, $type);
    push @$choices, map { $_->{p} } @$spread;
    push @$crumb_trail, "$action $type";
  }
  elsif ($action eq 'Reset') {
    ($deck) = Tarot::build_deck();
    $c->cookie(choice => '');
    $choices = [];
    $c->cookie(crumbs => '');
    $crumb_trail = ['Reset'];
    $orient = 0;
  }
  elsif ($action eq 'Choose') {
    Tarot::choose($deck, $choice);
    push @$choices, $choice;
    push @$crumb_trail, "Choose $choice";
  }
  elsif ($action eq 'Clear') {
    Tarot::clear($deck);
    $c->cookie(choice => '');
    $choices = [];
    $c->cookie(crumbs => '');
    $crumb_trail = [];
  }

  # remember the deck
  _store_deck($c, $deck, $session);

  # remember the choices and actions
  $c->cookie(choice => join '|', @$choices);
  $c->cookie(crumbs => join '|', @$crumb_trail);

  # get the cards that have been chosen
  my @choices;
  for my $n (@$choices) {
    my $card = ( grep { $deck->{$_}{p} == $n } keys %$deck )[0];
    push @choices, $deck->{$card};
  }

  $c->render(
    template => 'index',
    deck     => $deck,
    view     => $view,
    choices  => \@choices,
    crumbs   => $crumb_trail,
    orient   => $orient,
  );
} => 'index';

helper card_file => sub ($c, $card) {
  return Tarot::card_file($card);
};

app->log->level('info');

app->start;

sub _store_deck {
  my ($c, $deck, $session) = @_;
  ($deck) ||= Tarot::build_deck();
  unless ($session) {
    $session = time();
    $c->session(session => $session);
  }
  my $file = './deck-' . $session . '.dat';
  store($deck, $file);
  return $c->session('session');
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Court de Gébelin';

<div>

% # View
<form method="get" class="block">
  <input type="submit" name="action" title="View the deck" value="View" class="btn btn-sm btn-success" />
</form>

% # Reset
<form method="get" class="block">
  <input type="submit" name="action" title="Reset the deck" value="Reset" class="btn btn-sm btn-primary" />
</form>

% # Cut
<form method="get" class="block">
  <input type="hidden" name="action" value="Cut" />
  <select name="cut" title="Cut the deck" class="btn btn-sm" onchange="this.form.submit()">
    <option value="0" selected disabled>Cut</option>
% for my $n (1 .. keys %$deck) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>

% # Shuffle
<form method="get" class="block">
  <input type="submit" name="action" title="Shuffle the deck" value="Shuffle" class="btn btn-sm btn-info" />
  <div class="form-check form-check-inline">
% my $checked = $orient ? 'checked' : '';
    <input class="form-check-input" type="checkbox" name="orient" <%= $checked %> title="Shuffle with approximately half upside down" />
  </div>
</form>

<p></p>

% # Spread
<form method="get" class="block">
  <input type="hidden" name="action" value="Spread" />
  <select name="type" title="Generate a spread" onchange="this.form.submit()" class="btn btn-sm">
    <option value="0" selected disabled>Spread</option>
% for my $n (1 .. 10) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>

% # Choose
<form method="get" class="block">
  <input type="hidden" name="action" value="Choose" />
  <select name="choice" title="Choose a card" class="btn btn-sm" onchange="this.form.submit()">
    <option value="" selected disabled>Card</option>
% for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
%   my $n = $deck->{$card}{p};
%   my $disabled = $deck->{$card}{chosen} ? 'disabled' : '';
    <option value="<%= $n %>" <%= $disabled %>><%= $n %></option>
% }
  </select>
</form>

% # Clear
<form method="get" class="block">
  <input type="submit" name="action" title="Clear the choices" value="Clear" class="btn btn-sm btn-outline-dark" />
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
<!-- maybe...
  <p></p>
  <form method="get" class="block">
    <input type="text" name="name" title="Name for this saved reading" placeholder="Name" />
    <input type="submit" name="action" title="Save this reading" value="Save" class="btn btn-sm btn-dark" />
  </form>
-->
</div>
% }
% elsif ($view) {
<hr>
<div>
  <table cellpadding="2" border="0">
%   my $n = 0;
%   my $cells = 3;
%   for my $name (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
%   my $row = 0;
%     if ($n == 0 || $n % $cells == 0) {
    <tr>
%     }
      <td>
%       my $style = $deck->{$name}{o} ? 'transform: scaleY(-1);' : '';
        <a href="<%= $deck->{$name}{file} %>">
        <img src="<%= $deck->{$name}{file} %>" alt="<%= $name %>" title="<%= ucfirst $name %> (<%= $deck->{$name}{n} %>)" height="200" width="100" style="<%= $style %>" />
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
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous" onerror="this.onerror=null;this.href='bootstrap.min.css';" />
    <title><%= title %></title>
    <style>
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
    <div class="container" style="padding-top: 10px;">
      <h3><%= title %></h3>
      <%= content %>
      <p></p>
      <div id="footer" class="text-secondary">
        <hr>
        Built by <a href="http://gene.ology.net/">Gene</a>
        with <a href="https://www.perl.org/">Perl</a> and
        <a href="https://mojolicious.org/">Mojolicious</a>
      </div>
    </div>
  </body>
</html>
