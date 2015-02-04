use Inline::Perl6;

Inline::Perl6::initialize;
Inline::Perl6::run("use Test; ok(1);");
Inline::Perl6::run("use Test; ok(2); done();");
Inline::Perl6::destroy;
