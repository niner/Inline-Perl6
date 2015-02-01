package Inline::Perl6;

use strict;
use warnings;

use Inline C => config =>
    libs => "-L$ENV{HOME}/install/rakudo/install/lib -lmoar",
    inc => join(' ',
        map { "-I$ENV{HOME}/install/rakudo/install/include/$_" }
        qw(moar dynasm dyncall libatomic_ops libtommath libuv linenoise sha1 tinymt)
    ),
    optimize => '-g',
;

use Inline C => <<'END_OF_C';
#include <moar.h>

extern SV *(*call_method_callback)(IV, char *);
/*SV *(*call_method_callback)(IV, char *);*/

MVMInstance *instance;
const char *filename = "/home/nine/install/rakudo/inline.moarvm";

/* This callback is passed to the interpreter code. It takes care of making
 * the initial invocation. */
static void toplevel_initial_invoke(MVMThreadContext *tc, void *data) {
    /* Create initial frame, which sets up all of the interpreter state also. */
    MVM_frame_invoke(tc, (MVMStaticFrame *)data, MVM_callsite_get_common(tc, MVM_CALLSITE_ID_NULL_ARGS), NULL, NULL, NULL, -1);
}

MVMCompUnit *cu;

void p6_run_code(char *code) {
    const char *raw_clargs[1];
    instance->num_clargs = 1;
    raw_clargs[0] = code;
    instance->raw_clargs = raw_clargs;
    instance->clargs = NULL; /* clear cache */

    MVMThreadContext *tc = instance->main_thread;
    MVMStaticFrame *start_frame;

    start_frame = cu->body.main_frame ? cu->body.main_frame : cu->body.frames[0];
    MVM_interp_run(tc, &toplevel_initial_invoke, start_frame);
}

void p6_initialize() {
    const char  *executable_name = NULL;
    const char  *lib_path[8];

    int dump         = 0;
    int full_cleanup = 0;
    int argi         = 1;
    int lib_path_i   = 0;

    MVM_crash_on_error();

    instance   = MVM_vm_create_instance();
    lib_path[lib_path_i++] = "/home/nine/install/rakudo/install/languages/nqp/lib";
    lib_path[lib_path_i++] = "/home/nine/install/rakudo/install/languages/perl6/lib";
    lib_path[lib_path_i++] = "/home/nine/install/rakudo/install/languages/perl6/runtime";
    lib_path[lib_path_i++] = NULL;

    for( argi = 0; argi < lib_path_i; argi++)
        instance->lib_path[argi] = lib_path[argi];

    /* stash the rest of the raw command line args in the instance */
    instance->num_clargs = 0;
    instance->prog_name  = "/home/nine/install/rakudo/inline.moarvm";
    instance->exec_name  = "perl6";
    instance->raw_clargs = NULL;

    /* Map the compilation unit into memory and dissect it. */
    MVMThreadContext *tc = instance->main_thread;
    cu = MVM_cu_map_from_file(tc, filename);

    call_method_callback = NULL;

    MVMROOT(tc, cu, {
        /* The call to MVM_string_utf8_decode() may allocate, invalidating the
           location cu->body.filename */
        MVMString *const str = MVM_string_utf8_decode(tc, instance->VMString, filename, strlen(filename));
        cu->body.filename = str;

        /* Run deserialization frame, if there is one. */
        if (cu->body.deserialize_frame) {
            MVM_interp_run(tc, &toplevel_initial_invoke, cu->body.deserialize_frame);
        }
    });
    p6_run_code("use v6; use lib <lib>; use Inline::Perl6Helper;");

    /* Points to the current opcode. */
    MVMuint8 *cur_op = NULL;

    /* The current frame's bytecode start. */
    MVMuint8 *bytecode_start = NULL;

    /* Points to the base of the current register set for the frame we
     * are presently in. */
    MVMRegister *reg_base = NULL;

    /* The current call site we're constructing. */
    MVMCallsite *cur_callsite = NULL;

    /* Stash addresses of current op, register base and SC deref base
     * in the TC; this will be used by anything that needs to switch
     * the current place we're interpreting. */
    tc->interp_cur_op         = &cur_op;
    tc->interp_bytecode_start = &bytecode_start;
    tc->interp_reg_base       = &reg_base;
    tc->interp_cu             = &cu;
    toplevel_initial_invoke(tc, cu->body.main_frame);
}

void p6_destroy() {
    MVM_vm_exit(instance);
}

void p6_call_method(char *name) {
    MVMThreadContext *tc = instance->main_thread;
    call_method_callback(0, name);
}

END_OF_C

1;
