# Copyright (C) 2009-2022  Alex Schroeder <alex@gnu.org>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::TextMapper::Line - a line between two points

=head1 SYNOPSIS

    use Modern::Perl;
    use Game::TextMapper::Line::Hex;
    use Game::TextMapper::Point::Hex;
    my $line = Game::TextMapper::Line::Hex->new();
    my $from = Game::TextMapper::Point::Hex->new(x => 1, y => 1, z => 0);
    my $to   = Game::TextMapper::Point::Hex->new(x => 5, y => 3, z => 0);
    $line->points([$from, $to]);
    my @line = $line->compute_missing_points;
    say join(" ", map { $_->str } @line);
    # (1,1,0) (2,1,0) (3,2,0) (4,2,0) (5,3,0)

=head1 DESCRIPTION

The line connects two points. This class knows how to compute all the regions
between these two points, how to compute the next region along the line, and how
to output SVG.

In order to do this, the class needs to know how to work with the regions on the
map. This is different for hexes and squares. Therefore you should always be
using the appropriate Hex or Square class instead.

=cut

package Game::TextMapper::Line;

use Modern::Perl '2018';
use Mojo::Util qw(url_escape);
use Mojo::Base -base;

our $debug;

=head1 ATTRIBUTES

=head2 points

An array reference of points using a class derived from
L<Game::TextMapper::Point>, i.e. L<Game::TextMapper::Line::Hex> uses
L<Game::TextMapper::Point::Hex> and L<Game::TextMapper::Line::Square> uses
L<Game::TextMapper::Point::Square>.

=cut

has 'id';
has 'points';
has 'offset';
has 'type';
has 'label';
has 'map';
has 'side';
has 'start';

=head1 METHODS

=head2 compute_missing_points

Compute the missing points between the points in C<points> and return it.

=cut

sub compute_missing_points {
  my $self = shift;
  my $i = 0;
  my $current = $self->points->[$i++];
  my $z = $current->z;
  my @result = ($current);
  while ($self->points->[$i]) {
    $current = $self->one_step($current, $self->points->[$i]);
    return unless $z == $current->z; # must all be on the same plane
    push(@result, $current);
    $i++ if $current->equal($self->points->[$i]);
  }

  return @result;
}

sub partway {
  my ($self, $from, $to, $q) = @_;
  my ($x1, $y1) = $self->pixels($from);
  my ($x2, $y2) = $self->pixels($to);
  $q ||= 1;
  return $x1 + ($x2 - $x1) * $q, $y1 + ($y2 - $y1) * $q if wantarray;
  return sprintf("%.1f,%.1f", $x1 + ($x2 - $x1) * $q, $y1 + ($y2 - $y1) * $q);
}

=head2 svg($offset)

This returns an SVG fragment, a string with a C<path>.

=cut

sub svg {
  my ($self, $offset) = @_;
  my ($path, $current, $next, $closed);
  $self->offset($offset);
  my @points = $self->compute_missing_points();
  return '' unless @points;
  if ($points[0]->equal($points[$#points])) {
    $closed = 1;
  }

  if ($closed) {
    for my $i (0 .. $#points - 1) {
      $current = $points[$i];
      $next = $points[$i+1];
      if (!$path) {
	my $a = $self->partway($current, $next, 0.3);
	my $b = $self->partway($current, $next, 0.5);
	my $c = $self->partway($points[$#points-1], $current, 0.7);
	my $d = $self->partway($points[$#points-1], $current, 0.5);
	$path = "M$d C$c $a $b";
      } else {
	# continue curve
	my $a = $self->partway($current, $next, 0.3);
	my $b = $self->partway($current, $next, 0.5);
	$path .= " S$a $b";
      }
    }
  } else {
    for my $i (0 .. $#points - 1) {
      $current = $points[$i];
      $next = $points[$i+1];
      if (!$path) {
	# line from a to b; control point a required for following S commands
	my $a = $self->partway($current, $next, 0.3);
	my $b = $self->partway($current, $next, 0.5);
	$path = "M$a C$b $a $b";
      } else {
	# continue curve
	my $a = $self->partway($current, $next, 0.3);
	my $b = $self->partway($current, $next, 0.5);
	$path .= " S$a $b";
      }
    }
    # end with a little stub
    $path .= " L" . $self->partway($current, $next, 0.7);
  }

  my $id = $self->id;
  my $type = $self->type;
  my $attributes = $self->map->path_attributes->{$type};
  my $data = qq{    <path id="$id" $attributes d="$path"/>\n};
  $data .= $self->debug($closed) if $debug;
  return $data;
}

=head2 svg_label

This returns an SVG fragment, a group C<g> with C<text> and a C<textPath>
element.

=cut

sub svg_label {
  my ($self) = @_;
  return '' unless defined $self->label;
  my $id = $self->id;
  my $label = $self->label;
  my $attributes = $self->map->label_attributes || "";
  my $glow = $self->map->glow_attributes || "";
  my $url = $self->map->url;
  $url =~ s/\%s/url_escape($self->label)/e or $url .= url_escape($self->label) if $url;
  # Default side is left, but if the line goes from right to left, then "left"
  # means "upside down", so allow people to control it.
  my $pathAttributes = '';
  if ($self->side) {
    $pathAttributes = ' side="' . $self->side . '"';
  } elsif ($self->points->[1]->x < $self->points->[0]->x
	   or $#{$self->points} >= 2 and $self->points->[2]->x < $self->points->[0]->x) {
    $pathAttributes = ' side="right"';
  }
  if ($self->start) {
    $pathAttributes .= ' startOffset="' . $self->start . '"';
  }
  my $data = qq{    <g>\n};
  $data .= qq{      <text $attributes $glow><textPath$pathAttributes href='#$id'>$label</textPath></text>\n} if $glow;
  $data .= qq{      <a xlink:href="$url">} if $url;
  $data .= qq{      <text $attributes><textPath$pathAttributes href='#$id'>$label</textPath></text>\n};
  $data .= qq{      </a>} if $url;
  $data .= qq{    </g>\n};
  return $data;
}

sub debug {
  my ($self, $closed) = @_;
  my ($data, $current, $next);
  my @points = $self->compute_missing_points();
  for my $i (0 .. $#points - 1) {
    $current = $points[$i];
    $next = $points[$i+1];
    $data .= circle($self->pixels($current), 15, $i++);
    $data .= circle($self->partway($current, $next, 0.3), 3, 'a');
    $data .= circle($self->partway($current, $next, 0.5), 5, 'b');
    $data .= circle($self->partway($current, $next, 0.7), 3, 'c');
  }
  $data .= circle($self->pixels($next), 15, $#points);

  my ($x, $y) = $self->pixels($points[0]); $y += 30;
  $data .= "<text fill='#000' font-size='20pt' "
    . "text-anchor='middle' dominant-baseline='central' "
    . "x='$x' y='$y'>closed</text>"
      if $closed;

  return $data;
}

sub circle {
  my ($x, $y, $r, $i) = @_;
  my $data = "<circle fill='#666' cx='$x' cy='$y' r='$r'/>";
  $data .= "<text fill='#000' font-size='20pt' "
    . "text-anchor='middle' dominant-baseline='central' "
    . "x='$x' y='$y'>$i</text>" if $i;
  return "$data\n";
}

=head1 SEE ALSO

Lines consist of L<Game::TextMapper::Point> instances.

Use either L<Game::TextMapper::Line::Hex> or L<Game::TextMapper::Line::Square>
to implement lines.

=cut

1;
