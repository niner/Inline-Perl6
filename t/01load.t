use Inline::Perl6;

Inline::Perl6::p6_initialize;
Inline::Perl6::p6_call_method("1..2\n");
Inline::Perl6::p6_call_method('ok 1 - ');
Inline::Perl6::p6_call_method('ok 2 - ');
Inline::Perl6::p6_destroy;
