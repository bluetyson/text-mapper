# Copyright (C) 2009-2021  Alex Schroeder <alex@gnu.org>
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

package Game::TextMapper::Mapper::Square;

use Game::TextMapper::Constants qw($dy);
use Game::TextMapper::Square;
use Game::TextMapper::Line::Square;

use Modern::Perl '2018';
use Mojo::Base 'Game::TextMapper::Mapper';

sub make_region {
  my $self = shift;
  return Game::TextMapper::Square->new(@_);
}

sub make_line {
  my $self = shift;
  return Game::TextMapper::Line::Square->new(@_);
}

sub shape {
  my $self = shift;
  my $attributes = shift;
  my $half = $dy / 2;
  return qq{<rect $attributes x="-$half" y="-$half" width="$dy" height="$dy" />};
}

sub viewbox {
  my $self = shift;
  my ($minx, $miny, $maxx, $maxy) = @_;
  map { int($_) } (($minx - 1) * $dy, ($miny - 1) * $dy,
		   ($maxx + 1) * $dy, ($maxy + 1) * $dy);
}

1;
