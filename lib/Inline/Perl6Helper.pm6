module Inline::Perl6Helper;

use NativeCall;

sub p5_int_to_sv(Int --> OpaquePointer) is native(@*ARGS[0]) { * }
sub p5_str_to_sv(Str --> OpaquePointer) is native(@*ARGS[0]) { * }
sub p5_undef(--> OpaquePointer)         is native(@*ARGS[0]) { * }

multi sub p6_to_p5(Int:D $value) returns OpaquePointer {
    p5_int_to_sv($value);
}

multi sub p6_to_p5(Bool:D $value) returns OpaquePointer {
    p5_int_to_sv($value ?? 1 !! 0);
}

multi sub p6_to_p5(Str:D $value) returns OpaquePointer {
    p5_str_to_sv($value);
}

multi sub p6_to_p5(Any:U $value) returns OpaquePointer {
    p5_undef();
}

our $eval_code = sub (Str $code) returns OpaquePointer {
    return p6_to_p5(EVAL $code);
};

my $foo = 0;
our $call_method = sub (Int $index, Str $name) returns OpaquePointer {
    say $name, $foo++;
    return OpaquePointer;
};

our $call_function = sub (Str $name) returns OpaquePointer {
    return p6_to_p5(&::($name)());
};

sub init_callbacks(
    &eval_code (Str --> OpaquePointer),
    &call_method (Int, Str --> OpaquePointer),
    &call_function (Str --> OpaquePointer),
) is native(@*ARGS[0]) { * };

init_callbacks($eval_code, $call_method, $call_function);
