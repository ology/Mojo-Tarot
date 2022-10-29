#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Data::Dumper::Compact qw(ddc);

use lib 'lib';
use Tarot;

get '/' => sub ($c) {
  my $type   = $c->param('type');
  my $cut    = $c->param('cut');
  my $submit = $c->param('action') || '';
  my $choice = $c->param('choice');

  my $choices = $c->cookie('choices') || '';
  $choices = [ split /\|/, $choices ];
  push @$choices, $choice if $choice;
  $c->cookie(choices => join '|', @$choices);

  my $orientations = $c->cookie('orient') || '';
  $orientations = [ split /\|/, $orientations ];

  my $deck = $c->cookie('deck') || '';
  $deck = [ split /\|/, $deck ];

  my $full_deck = Tarot::build_deck();

  my $crumb_trail = $c->cookie('crumbs') || '';
  $crumb_trail = [ split /\|/, $crumb_trail ];

  my ($view, $spread) = (0, 0);

  if ($submit eq 'View') {
    $view = 1;
  }
  elsif ($submit eq 'Shuffle') {
    $deck = Tarot::shuffle_deck($deck);
    push @$crumb_trail, $submit;
  }
  elsif ($submit eq 'Cut') {
    ($orientations, $deck) = Tarot::cut_deck($orientations, $deck, $cut);
    push @$crumb_trail, "$submit $cut";
  }
  elsif ($submit eq 'Spread') {
    $spread = Tarot::spread($deck, $type);
    push @$crumb_trail, "$submit $type";
    $c->cookie(choices => '');
    $choices = [];
  }
  elsif ($submit eq 'Clear') {
    $c->cookie(crumbs => '');
    $crumb_trail = [];
    $c->cookie(choices => '');
    $choices = [];
  }
  elsif ($submit eq 'Reset') {
    $deck = Tarot::build_deck();
    $c->cookie(orient => '');
    $c->cookie(crumbs => '');
    $crumb_trail = ['Reset'];
  }
  else {
    push @$crumb_trail, "Choose $choice" if $choice;
  }

  $c->cookie(crumbs => join '|', @$crumb_trail);
  $c->cookie(deck => join '|', @$deck);

  my $choice_cards = [ map { [ Tarot::choose($deck, $_) ] } @$choices ];

#  unless ($submit eq 'Reset' && @$orientations) {
#    $orientations = [ map { int rand 2 } @$deck ];
#  }
#  $c->cookie(orient => join '|', @$orientations);

  $c->render(
    template => 'index',
    deck     => $deck,
    orient   => $orientations,
    view     => $view,
    spread   => $spread,
    choices  => $choice_cards,
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
% for my $n (1 .. $#$deck) {
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
% for my $n (1 .. @$deck) {
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
  <img src="<%= $card->[1] %>" alt="<%= $card->[0] %>" title="<%= $card->[0] %>" height="200" width="100" />
%   }
</div>
% }
% elsif ($spread) {
<hr>
<div>
%   for my $card (@$spread) {
  <img src="<%= $card->[1] %>" alt="<%= $card->[0] %>" title="<%= $card->[0] %>" height="200" width="100" />
%   }
</div>
% }
% elsif ($view) {
<hr>
<div>
  <table cellpadding="2" border="0">
%   my $cells = 3;
%   for my $n (0 .. $#$deck) {
%     my $row = 0;
%     if ($n == 0 || $n % $cells == 0) {
    <tr>
%     }
      <td>
%       my $style = $orient->[$n] ? 'transform: scaleY(-1);' : '';
        <img src="/images/<%= $deck->[$n] %>.jpeg" alt="<%= $deck->[$n] %>" title="<%= $deck->[$n] %>" height="200" width="100" style="<%= $style %>"/>
      </td>
%     if ($row == $cells - 1) {
%     $row = 0;
    </tr>
%     } else {
%       $row++;
%     }
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
