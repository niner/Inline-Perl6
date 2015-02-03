module Inline::Perl6Helper;

use NativeCall;

our $eval_code = sub (Str $code) returns OpaquePointer {
    EVAL $code;
    return OpaquePointer;
};

my $foo = 0;
our $call_method = sub (Int $index, Str $name) returns OpaquePointer {
    say $name, $foo++;
    return OpaquePointer;
};

sub init_callbacks(
    &eval_code (Str --> OpaquePointer),
    &call_method (Int, Str --> OpaquePointer)
) is native(@*ARGS[0]) { * };

init_callbacks($eval_code, $call_method);
