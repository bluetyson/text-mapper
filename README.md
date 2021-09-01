# Text Mapper

This application takes a textual representation of a map and produces
SVG output.

Example input:

    0101 empty
    0102 mountain
    0103 hill "bone hills"
    0104 forest

[Try it](https://campaignwiki.org/text-mapper).

The app comes with a tutorial built in. See the
[Help](https://campaignwiki.org/text-mapper/help) link.

## Dependencies

Perl Modules (or Debian modules):

* IO::Socket::SSL or libio-socket-ssl-perl
* LWP::UserAgent or liblwp-useragent-perl
* List::MoreUtils or liblist-moreutils-perl
* Modern::Perl or libmodern-perl-perl
* Mojolicious or libmojolicious-perl
* Role::Tiny::With

The IO::Socket::SSL dependency means that you’ll need OpenSSL
development libraries installed as well: openssl-devel or equivalent,
depending on your package manager.

To install from the working directory (which will also install all the
dependencies) use cpan or cpanm.

Example:

```
cpanm .
```

## Installation

Use cpan or cpanm to install Game::TextMapper. In the directory you
want to run it from, create a config file like the following:

```
{
  # choose error, warn, info, or debug
  loglevel => 'warn',
  # use stderr, alternatively use a filename
  logfile => undef,
  # the URL where the contributions for include statements are
  # e.g. 'https://campaignwiki.org/contrib'
  contrib => 'file:///home/alex/src/text-mapper/share',
}
```

As a developer, morbo makes sure to restart it whenever a file
changes:

```
morbo --mode development --listen "http://*:3010" script/text-mapper
```

Alternatively:

```
script/text-mapper daemon --mode development --listen "http://*:3010"
```
