use Test::More tests => 1;
use Inline::Perl6;

Inline::Perl6::initialize;
ok(1);
Inline::Perl6::call('exit');
ok(0);
Inline::Perl6::destroy;

