use Test::More;
use Inline::Perl6;

ok(1);
Inline::Perl6::initialize;
ok(1);
Inline::Perl6::destroy;
ok(1);

done_testing;
