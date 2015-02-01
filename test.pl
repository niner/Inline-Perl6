use Inline::Perl6;

Inline::Perl6::p6_initialize;
Inline::Perl6::p6_call_method('foo');
Inline::Perl6::p6_call_method('bar');
Inline::Perl6::p6_call_method('baz');
Inline::Perl6::p6_destroy;
