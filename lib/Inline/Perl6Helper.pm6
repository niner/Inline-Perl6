class Inline::Perl6Helper;

use NativeCall;

class Perl5Interpreter is repr('CPointer') { }

has Perl5Interpreter $!p5;

sub p5_int_to_sv(Perl5Interpreter, Int --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_float_to_sv(Perl5Interpreter, num64 --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_str_to_sv(Perl5Interpreter, Str --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_buf_to_sv(Perl5Interpreter, Int, CArray[uint8] --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_undef(Perl5Interpreter, --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_sv_to_av(Perl5Interpreter, OpaquePointer --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_av_fetch(Perl5Interpreter, OpaquePointer, int32 --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_av_push(Perl5Interpreter, OpaquePointer, OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_av_top_index(Perl5Interpreter, OpaquePointer --> int32)
    is native(@*ARGS[0]) { * }
sub p5_SvPOK(Perl5Interpreter, OpaquePointer --> int32)
    is native(@*ARGS[0]) { * }
sub p5_sv_to_buf(Perl5Interpreter, OpaquePointer, CArray[CArray[int8]] --> Int)
    is native(@*ARGS[0]) { * }
sub p5_sv_to_char_star(Perl5Interpreter, OpaquePointer --> Str)
    is native(@*ARGS[0]) { * }
sub p5_sv_utf8(Perl5Interpreter, OpaquePointer --> int32)
    is native(@*ARGS[0]) { * }
sub p5_newHV(Perl5Interpreter --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_newAV(Perl5Interpreter --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_newRV_noinc(Perl5Interpreter, OpaquePointer --> OpaquePointer)
    is native(@*ARGS[0]) { * }
sub p5_hv_store(Perl5Interpreter, OpaquePointer, Str, OpaquePointer)
    is native(@*ARGS[0]) { * }

multi method p6_to_p5(Int:D $value) returns OpaquePointer {
    p5_int_to_sv($!p5, $value);
}
multi method p6_to_p5(Bool:D $value) returns OpaquePointer {
    p5_int_to_sv($!p5, $value ?? 1 !! 0);
}
multi method p6_to_p5(Num:D $value) returns OpaquePointer {
    p5_float_to_sv($!p5, $value);
}
multi method p6_to_p5(Rat:D $value) returns OpaquePointer {
    p5_float_to_sv($!p5, $value.Num);
}
multi method p6_to_p5(Str:D $value) returns OpaquePointer {
    p5_str_to_sv($!p5, $value);
}
multi method p6_to_p5(blob8:D $value) returns OpaquePointer {
    my $array = CArray[uint8].new();
    for ^$value.elems {
        $array[$_] = $value[$_];
    }
    p5_buf_to_sv($!p5, $value.elems, $array);
}
multi method p6_to_p5(OpaquePointer $value) returns OpaquePointer {
    $value;
}
multi method p6_to_p5(Any:U $value) returns OpaquePointer {
    p5_undef($!p5);
}
multi method p6_to_p5(Hash:D $value) returns OpaquePointer {
    my $hv = p5_newHV($!p5);
    for %$value -> $item {
        my $value = self.p6_to_p5($item.value);
        p5_hv_store($!p5, $hv, $item.key, $value);
    }
    p5_newRV_noinc($!p5, $hv);
}
multi method p6_to_p5(Positional:D $value) returns OpaquePointer {
    my $av = p5_newAV($!p5);
    for @$value -> $item {
        p5_av_push($!p5, $av, self.p6_to_p5($item));
    }
    p5_newRV_noinc($!p5, $av);
}

method p5_to_p6(OpaquePointer $value) {
    return Any unless defined $value;
#   if p5_is_object($!p5, $value) {
#       if p5_is_wrapped_p6_object($!p5, $value) {
#           return $objects.get(p5_unwrap_p6_object($!p5, $value));
#       }
#       else {
#           p5_sv_refcnt_inc($!p5, $value);
#           return Perl5Object.new(perl5 => self, ptr => $value);
#       }
#   }
#   elsif p5_is_sub_ref($!p5, $value) {
#       p5_sv_refcnt_inc($!p5, $value);
#       return Perl5Callable.new(perl5 => self, ptr => $value);
#   }
#   elsif p5_SvNOK($!p5, $value) {
#       return p5_sv_nv($!p5, $value);
#   }
#   elsif p5_SvIOK($!p5, $value) {
#       return p5_sv_iv($!p5, $value);
#   }
    if p5_SvPOK($!p5, $value) {
        if p5_sv_utf8($!p5, $value) {
            return p5_sv_to_char_star($!p5, $value);
        }
        else {
            my $string_ptr = CArray[CArray[int8]].new;
            $string_ptr[0] = CArray[int8];
            my $len = p5_sv_to_buf($!p5, $value, $string_ptr);
            my $buf = Buf.new;
            for 0..^$len {
                $buf[$_] = $string_ptr[0][$_];
            }
            return $buf;
        }
    }
#   elsif p5_is_array($!p5, $value) {
#       return self.p5_array_to_p6_array($value);
#   }
#   elsif p5_is_hash($!p5, $value) {
#       return self!p5_hash_to_p6_hash($value);
#   }
#   elsif p5_is_undef($!p5, $value) {
#       return Any;
#   }
    die "Unsupported type $value in p5_to_p6";
}

method p5_array_to_p6_array(OpaquePointer $sv) {
    my $av = p5_sv_to_av($!p5, $sv);
    my $av_len = p5_av_top_index($!p5, $av);

    my $arr = [];
    loop (my int $i = 0; $i <= $av_len; $i = $i + 1) {
        $arr.push(self.p5_to_p6(p5_av_fetch($!p5, $av, $i)));
    }
    $arr;
}

sub init_callbacks(
    &eval_code (Str --> OpaquePointer),
    &call_method (Int, Str --> OpaquePointer),
    &call_function (Str, OpaquePointer --> OpaquePointer),
) is native(@*ARGS[0]) { * };

sub init_p5_callback(&init_p5 (Perl5Interpreter)) is native(@*ARGS[0]) { * };

submethod BUILD {
    init_p5_callback(sub (Perl5Interpreter $p5) {
        $!p5 = $p5;
        self.init_callbacks;
    });
}

method init_callbacks () {
    my $eval_code = sub (Str $code) returns OpaquePointer {
        return self.p6_to_p5(EVAL $code);
    };

    my $foo = 0;
    my $call_method = sub (Int $index, Str $name) returns OpaquePointer {
        say $name, $foo++;
        return OpaquePointer;
    };

    my $call_function = sub (Str $name, OpaquePointer $args) returns OpaquePointer {
        return self.p6_to_p5(&::($name)(|self.p5_array_to_p6_array($args)));
    };

    init_callbacks($eval_code, $call_method, $call_function);
}
