use Test::More;
use Inline::Perl6;

Inline::Perl6::initialize;
is(Inline::Perl6::run("1;"), 1);
is(Inline::Perl6::run("'yes'"), 'yes');
Inline::Perl6::destroy;

done_testing;
