#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

use Data::Dumper::Compact qw(ddc);
use Storable qw(retrieve store);

use lib 'lib';
use Tarot ();

# TODO Purge old session decks

get '/' => sub ($c) {
  my $type   = $c->param('type');
  my $cut    = $c->param('cut');
  my $submit = $c->param('action') || '';
  my $choice = $c->param('choice');
  my $orient = $c->param('orient') || 0;

  my $deck;
  my $session = $c->session('session');
  my $session_file = './deck-' . $session . '.dat';
  if ($session && -e $session_file) {
    $deck = retrieve $session_file;
  }
  else {
    $session = _store_deck($c);
    $c->app->log->info("Made new session deck $session");
  }

  my $choices = $c->cookie('choice') || '';
  $choices = [ split /\|/, $choices ];

  my $crumb_trail = $c->cookie('crumbs') || '';
  $crumb_trail = [ split /\|/, $crumb_trail ];

  my ($view, $spread) = (0, 0);

  if ($submit eq 'View') {
    $view = 1;
  }
  elsif ($submit eq 'Shuffle') {
    ($deck) = Tarot::shuffle_deck($deck, $orient);
    push @$crumb_trail, $submit;
  }
  elsif ($submit eq 'Cut') {
    ($deck) = Tarot::cut_deck($deck, $cut);
    push @$crumb_trail, "$submit $cut";
  }
  elsif ($submit eq 'Spread') {
    ($spread) = Tarot::spread($deck, $type);
    push @$choices, map { $_->{p} } @$spread;
    push @$crumb_trail, "$submit $type";
  }
  elsif ($submit eq 'Reset') {
    ($deck) = Tarot::build_deck();
    $c->cookie(choice => '');
    $choices = [];
    $c->cookie(crumbs => '');
    $crumb_trail = ['Reset'];
    $orient = 0;
  }
  elsif ($submit eq 'Choose') {
    Tarot::choose($deck, $choice);
    push @$choices, $choice;
    push @$crumb_trail, "Choose $choice";
  }
  elsif ($submit eq 'Clear') {
    Tarot::clear($deck);
    $c->cookie(choice => '');
    $choices = [];
    $c->cookie(crumbs => '');
    $crumb_trail = [];
  }

  _store_deck($c, $deck, $session);

  $c->cookie(choice => join '|', @$choices);
  $c->cookie(crumbs => join '|', @$crumb_trail);

  my @choices;
  for my $n (@$choices) {
    my $card = ( grep { $deck->{$_}{p} == $n } keys %$deck )[0];
    push @choices, $deck->{$card};
  }

  $c->render(
    template => 'index',
    deck     => $deck,
    view     => $view,
    spread   => $spread,
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
  unless ($session) {
    ($deck) = Tarot::build_deck();
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
% title 'Tarot Viewer';

<div>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="View the deck" value="View" class="btn btn-sm btn-success" />
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="Reset the deck" value="Reset" class="btn btn-sm btn-primary" />
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="Shuffle the deck" value="Shuffle" class="btn btn-sm btn-warning" />
  <div class="form-check form-check-inline">
% my $checked = $orient ? 'checked' : '';
    <input class="form-check-input" type="checkbox" name="orient" <%= $checked %> title="50% upside down" />
  </div>
</form>
<form method="get" style="display: inline-block;">
  <input type="hidden" name="action" value="Cut" />
  <select name="cut" title="Cut the deck" class="btn btn-mini" onchange="this.form.submit()">
    <option value="0" selected disabled>Cut</option>
% for my $n (1 .. keys %$deck) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>
<br>
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
% for my $card (sort { $deck->{$a}{p} <=> $deck->{$b}{p} } keys %$deck) {
%   my $n = $deck->{$card}{p};
%   my $disabled = $deck->{$card}{chosen} ? 'disabled' : '';
    <option value="<%= $n %>" <%= $disabled %>><%= $n %></option>
% }
  </select>
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="action" title="Clear the choices" value="Clear" class="btn btn-sm btn-outline-dark" />
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
%     my $style = $card->{o} ? 'transform: scaleY(-1);' : '';
  <img src="<%= $card->{file} %>" alt="<%= $card->{name} %>" title="<%= $card->{name} %> (<%= $card->{p} %>)" height="200" width="100" style="<%= $style %>" />
%   }
</div>
% }
% elsif ($spread) {
<hr>
<div>
%   for my $card (@$spread) {
%     my $style = $card->{o} ? 'transform: scaleY(-1);' : '';
  <img src="<%= $card->{file} %>" alt="<%= $card->{name} %>" title="<%= $card->{name} %> (<%= $card->{p} %>)" height="200" width="100" style="<%= $style %>" />
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
%       my $style = $deck->{$name}{o} ? 'transform: scaleY(-1);' : '';
        <img src="<%= $deck->{$name}{file} %>" alt="<%= $name %>" title="<%= $name %> (<%= $deck->{$name}{p} %>)" height="200" width="100" style="<%= $style %>" />
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

    <script src="https://code.jquery.com/jquery-3.2.1.slim.min.js" integrity="sha384-KJ3o2DKtIkvYIK3UENzmM7KCkRr/rE9/Qpg6aAZGJwFDMVNA/GpGFF93hXpG5KkN" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.12.9/dist/umd/popper.min.js" integrity="sha384-ApNbgh9B+Y1QKtv3Rn7W3mgPxhU9K/ScQsAP7hUibX39j7fakFPskvXusvfa0b4Q" crossorigin="anonymous"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.0.0/dist/js/bootstrap.min.js" integrity="sha384-JZR6Spejh4U02d8jOt6vLEHfe/JQGiRRSQQxSfFWpi1MquVdAyjUar5+76PVCmYl" crossorigin="anonymous"></script>

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
