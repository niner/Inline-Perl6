module Inline::Perl6Helper;

use NativeCall;

my $foo = 0;
our $call_method = sub (Int $index, Str $name) returns OpaquePointer {
    say $name, $foo++;
    return OpaquePointer;
};

sub init_call_method(&call_method (Int, Str --> OpaquePointer)) is native(@*ARGS[0]) { * };

init_call_method($call_method);
