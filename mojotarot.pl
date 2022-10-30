#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper::Compact qw(ddc);
use Storable qw(retrieve store);

use lib 'lib';
use Tarot ();

get '/' => sub ($c) {
  my $type   = $c->param('type');
  my $cut    = $c->param('cut');
  my $submit = $c->param('action') || '';
  my $choice = $c->param('choice');

  my $deck;
  my $session = $c->session('session');
  if ($session) {
    $deck = retrieve './deck-' . $session . '.dat';
  }
  else {
    _store_deck($c);
  }

  my $crumb_trail = $c->cookie('crumbs') || '';
  $crumb_trail = [ split /\|/, $crumb_trail ];

  my ($view, $spread) = (0, 0);

  if ($submit eq 'View') {
    $view = 1;
  }
  elsif ($submit eq 'Shuffle') {
    ($deck) = Tarot::shuffle_deck($deck);
    push @$crumb_trail, $submit;
    _store_deck($c, $deck);
  }
  elsif ($submit eq 'Cut') {
    ($deck) = Tarot::cut_deck($deck, $cut);
    push @$crumb_trail, "$submit $cut";
    _store_deck($c, $deck);
  }
  elsif ($submit eq 'Spread') {
    ($spread) = Tarot::spread($deck, $type);
    push @$crumb_trail, "$submit $type";
    _store_deck($c, $deck);
  }
  elsif ($submit eq 'Clear') {
    $c->cookie(crumbs => '');
    $crumb_trail = [];
  }
  elsif ($submit eq 'Reset') {
    ($deck) = Tarot::build_deck();
    _store_deck($c, $deck);
    $c->cookie(crumbs => '');
    $crumb_trail = ['Reset'];
  }
  elsif ($submit eq 'Choose') {
    Tarot::choose($deck, $choice);
    push @$crumb_trail, "Choose $choice";
  }

  $c->cookie(crumbs => join '|', @$crumb_trail);

  my @choices;
  my $remaining_in_deck;
  for my $card (keys %$deck) {
    if ($deck->{$card}{chosen}) {
      push @choices, $deck->{$card};
    }
    else {
      $remaining_in_deck++;
    }
  }

  $c->render(
    template => 'index',
    deck     => $deck,
    remain   => $remaining_in_deck,
    view     => $view,
    spread   => $spread,
    choices  => \@choices,
    crumbs   => $crumb_trail,
  );
} => 'index';

get '/reset' => sub ($c) {
  $c->cookie(deck => '');
  $c->redirect_to('index');
} => 'reset';

helper card_file => sub ($c, $card) {
  return Tarot::card_file($card);
};

app->start;

sub _store_deck {
  my ($c, $deck) = @_;
  ($deck) ||= Tarot::build_deck();
  # TODO Purge old session decks
  my $stamp = time();
  store($deck, './deck-' . $stamp . '.dat');
  $c->session(session => $stamp);
}

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Tarot Viewer';

<div>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="View the deck" value="View" class="btn btn-success" />
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="Unsort the deck" value="Reset" class="btn btn-primary" />
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="Shuffle the deck" value="Shuffle" class="btn btn-warning" />
</form>
<form method="get" style="display: inline-block;">
  <input type="hidden" name="action" value="Cut" />
  <select name="cut" title="Cut the deck" class="btn btn-mini" onchange="this.form.submit()">
    <option value="0" selected disabled>Cut</option>
% for my $n (1 .. $remain) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>
<form method="get" style="display: inline-block;">
  <input type="hidden" name="action" value="Spread" />
  <select name="type" title="Generate a spread" onchange="this.form.submit()" class="btn btn-mini">
    <option value="0" selected disabled>Spread</option>
% for my $n (1 .. 10) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>
<form method="get" style="display: inline-block;">
  <input type="hidden" name="action" value="Choose" />
  <select name="choice" title="Choose a card" class="btn btn-mini" onchange="this.form.submit()">
    <option value="0" selected disabled>From deck</option>
% for my $n (1 .. $remain) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="Clear the choices" value="Clear" class="btn btn-outline-dark" />
</form>
</div>

<p></p>

% if (@$crumbs) {
<%= join ' > ', @$crumbs %>
% }

% if (@$choices) {
<hr>
<div>
%   for my $card (@$choices) {
  <img src="<%= $card->{file} %>" alt="<%= $card->{name} %>" title="<%= $card->{name} %>" height="200" width="100" />
%   }
</div>
% }
% elsif ($spread) {
<hr>
<div>
%   for my $card (@$spread) {
  <img src="<%= $card->{file} %>" alt="<%= $card->{name} %>" title="<%= $card->{name} %>" height="200" width="100" />
%   }
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
%       #my $style = $orient->[$n] ? 'transform: scaleY(-1);' : '';
        <img src="<%= $deck->{$name}{file} %>" alt="<%= $name %>" title="<%= $name %>" height="200" width="100"/>
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
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.0.0/css/bootstrap.min.css" integrity="sha384-Gn5384xqQ1aoWXA+058RXPxPg6fy4IWvTNh0E263XmFcJlSAwiGgFAW/dAiS6JXm" crossorigin="anonymous">
    <title><%= title %></title>
  </head>
  <body>
    <div class="container" style="padding-top: 10px;">
      <h1><%= title %></h1>
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
