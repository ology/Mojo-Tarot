#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Data::Dumper::Compact qw(ddc);

use lib 'lib';
use Tarot;

get '/' => sub ($c) {
  my $type   = $c->param('type');
  my $cut    = $c->param('cut');
  my $submit = $c->param('mysubmit') || '';

  my $choice  = $c->param('choice');
  my $choices = $c->cookie('choices') || '';
  $choices = [ split /\|/, $choices ];
  push @$choices, $choice if $choice;
  $c->cookie(choices => join '|', @$choices);

  my $deck = $c->cookie('deck') || '';
  $deck = [ split /\|/, $deck ];

  my ($view, $spread) = (0, 0);

  if ($submit eq 'View') {
    $view = 1;
  }
  elsif ($submit eq 'Shuffle') {
    $deck = Tarot::shuffle_deck($deck);
  }
  elsif ($submit eq 'Cut') {
    $deck = Tarot::cut_deck($deck, $cut);
  }
  elsif ($submit eq 'Spread') {
    $spread = Tarot::spread($deck, $type);
  }
  elsif ($submit eq 'Clear') {
    $c->cookie(choices => '');
    $choices = [];
  }
  else {
    $deck = Tarot::build_deck();
  }

  $c->cookie(deck => join '|', @$deck);

  $choices = [ map { [ Tarot::choose($deck, $_) ] } @$choices ];

  $c->render(
    template => 'index',
    deck => $deck,
    view => $view,
    spread => $spread,
    choices => $choices,
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
% title 'Tarot!';

<div>
<button class="btn btn-primary" title="Unsort the deck" onclick="window.location.href='/'">Home</button>
<form method="get" style="display: inline-block;">
  <input type="submit" name="mysubmit" title="View the deck" value="View" class="btn btn-success" />
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="mysubmit" title="Shuffle the deck" value="Shuffle" class="btn btn-warning" />
</form>
<form method="get" style="display: inline-block;">
  <input type="hidden" name="mysubmit" value="Cut" />
  <select name="cut" title="Cut the deck" class="btn btn-mini" onchange="this.form.submit()">
    <option value="0" selected disabled>Cut...</option>
% for my $n (1 .. $#$deck) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>
<!--
<form method="get" style="display: inline-block;">
  <input type="hidden" name="mysubmit" value="Spread" />
  <select name="type" title="Generate a spread" onchange="this.form.submit()" class="btn btn-mini">
    <option value="0" selected disabled>Spread...</option>
    <option value="3">Three Card Spread</option>
    <option value="7">Seven Card Spread</option>
    <option value="10">Ten Card Spread</option>
  </select>
</form>
-->
<form method="get" style="display: inline-block;">
  <input type="hidden" name="mysubmit" value="Choose" />
  <select name="choice" title="Choose a card" class="btn btn-mini" onchange="this.form.submit()">
    <option value="0" selected disabled>Choose...</option>
% for my $n (1 .. @$deck) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
</form>
<form method="get" style="display: inline-block;">
  <input type="submit" name="mysubmit" title="Clear the choices" value="Clear" class="btn btn-light" />
</form>
</div>

<p></p>

% if (@$choices) {
<div>
%   for my $card (@$choices) {
  <img src="<%= $card->[2] %>" alt="<%= $card->[0] %>" title="<%= $card->[0] %>" height="200" width="100" />
%   }
</div>
% }
% elsif ($spread) {
<div>
%   for my $card (@$spread) {
  <img src="<%= $card->[2] %>" alt="<%= $card->[0] %>" title="<%= $card->[0] %>" height="200" width="100" />
%   }
</div>
% }
% elsif ($view) {
<div>
  <table cellpadding="2" border="0">
%   my $cells = 6;
%   for my $n (0 .. $#$deck) {
%     my $row = 0;
%     if ($n == 0 || $n % $cells == 0) {
    <tr>
%     }
      <td>
        <img src="/images/<%= $deck->[$n] %>.jpeg" alt="<%= $deck->[$n] %>" title="<%= $deck->[$n] %>" height="200" width="100" />
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
