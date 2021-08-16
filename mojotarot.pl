#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Data::Dumper::Compact qw(ddc);

use lib 'lib';
use Tarot;

get '/' => sub ($c) {
  my $type = $c->param('type');
  my $cut = $c->param('cut');
  my $submit = $c->param('mysubmit') || '';
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
  else {
    $deck = Tarot::build_deck();
  }
  $c->cookie(deck => join '|', @$deck);
  $c->render(
    template => 'index',
    deck => $deck,
    view => $view,
    spread => $spread,
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
<button onclick="window.location.href='/'">Start Over</button>
|
<form method="get" style="display: inline-block;">
  <input type="submit" name="mysubmit" title="View the deck" value="View" />
</form>
|
<form method="get" style="display: inline-block;">
  <input type="submit" name="mysubmit" title="Shuffle the deck" value="Shuffle" />
</form>
|
<form method="get" style="display: inline-block;">
  <select name="cut">
% for my $n (1 .. @$deck) {
    <option value="<%= $n %>"><%= $n %></option>
% }
  </select>
  <input type="submit" name="mysubmit" title="Cut the deck" value="Cut" />
</form>
|
<form method="get" style="display: inline-block;">
  <input type="hidden" name="mysubmit" value="Spread" />
  <select name="type" onchange="this.form.submit()">
    <option value="0" selected disabled>Spread...</option>
    <option value="3">Three Card Spread</option>
    <option value="7">Seven Card Spread</option>
    <option value="10">Ten Card Spread</option>
  </select>
</form>
</div>

% if ($spread) {
<div>
  <p></p>
% for my $card (@$spread) {
  <img src="<%= $card->[2] %>" alt="<%= $card->[0] %>" title="<%= $card->[0] %>" height="200" width="100" />
% }
</div>
% }

% if ($view) {
<div>
  <p></p>
  <table cellpadding="2" border="0">
% my $cells = 6;
% for my $n (0 .. $#$deck) {
%   my $row = 0;
%   if ($n == 0 || $n % $cells == 0) {
    <tr>
%   }
      <td>
        <img src="/images/<%= $deck->[$n] %>.jpeg" alt="<%= $deck->[$n] %>" title="<%= $deck->[$n] %>" height="200" width="100" />
      </td>
%   if ($row == $cells - 1) {
%     $row = 0;
    </tr>
%   } else {
%     $row++;
%   }
% }
  </table>
</div>
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
