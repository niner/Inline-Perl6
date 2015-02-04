use Inline::Perl6;

Inline::Perl6::initialize;
Inline::Perl6::call_method("1..2\n");
Inline::Perl6::call_method('ok 1 - ');
Inline::Perl6::call_method('ok 2 - ');
Inline::Perl6::destroy;
