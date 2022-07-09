package Inline::Raku;

use 5.018000;
use strict;
use warnings;

require Inline::Perl6;
our @ISA = qw(Inline::Perl6);

our $VERSION = '0.09';

1;
__END__

=head1 NAME

Inline::Raku - use the real Raku from Perl 5 code

=head1 SYNOPSIS

  use Inline::Raku;

  v6::run("say 'Hello from Raku'");
  v6::call("say", "Hello again from Raku");
  my $obj = v6::invoke("Some::Raku::Class", "new", "First arg");
  $obj->some_method(1, 2);

  # or object oriented:

  use Inline::Raku 'OO';

  my $raku = Inline::Raku->new;
  $raku->run("use Test; ok(1);");
  $raku->run("use Test; ok(2); done-testing();");

  $raku->use('Foo');
  my $foo = $raku->invoke('Foo', 'new');
  my $baz = $foo->bar('baz');

=head1 DESCRIPTION

This module embeds a MoarVM based Rakudo and allows you to run Raku
code, load Raku modules, use methods of Raku objects and much more.
Please look at https://github.com/niner/Inline-Perl5 for more information
about usage.

=head1 INSTALLATION

This module requires an up to date Rakudo with an enabled MoarVM backend.
The perl6 executable needs to be in your PATH when you run Makefile.PL.
You need to install the Inline::Perl5 Raku module which this module is
based on. You may do this using the "panda" or "zef" Raku module installer:

  panda install Inline::Perl5
  perl Makefile.PL
  make
  make test
  make install

Please note that if you have multiple perl installations (e.g. with perlbrew),
you have to use the exact same perl for installing Inline::Perl5 and
Inline::Raku.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<http://github.com/niner/Inline-Perl5> for more documentation.

L<http://github.com/niner/Inline-Perl6> for the latest version.

=head1 AUTHOR

Stefan Seifert, E<lt>nine@detonation.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Stefan Seifert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.
