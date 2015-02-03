module Inline::Perl6Helper;

use NativeCall;

sub native(Sub $sub) {
    my $so = 'p6helper.so';
    state Str $path;
    unless $path {
        for @*INC {
            if "$_/Inline/$so".IO ~~ :f {
                $path = "$_/Inline/$so";
                last;
            }
        }
    }
    unless $path {
        die "unable to find Inline/$so IN \@*INC";
    }
    trait_mod:<is>($sub, :native($path));
}

my $foo = 0;
our $call_method = sub (Int $index, Str $name) returns OpaquePointer {
    say $name, $foo++;
    return OpaquePointer;
};

sub init_call_method(&call_method (Int, Str --> OpaquePointer)) is native('/home/nine/Inline-Perl6/blib/arch/auto/Inline/Perl6/Perl6.so') { * };

init_call_method($call_method);
