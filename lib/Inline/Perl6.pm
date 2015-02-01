package Inline::Perl6;

use strict;
use warnings;

use Inline C => Config =>
    LIBS => "-L$ENV{HOME}/install/rakudo/install/lib -lmoar",
    INC => join(' ',
        map { "-I$ENV{HOME}/install/rakudo/install/include/$_" }
        qw(moar dynasm dyncall libatomic_ops libtommath libuv linenoise sha1 tinymt)
    ),
;

use Inline C => <<END_OF_C;
#include <moar.h>

MVMInstance *instance;
const char *filename = "/home/nine/install/rakudo/inline.moarvm";

/* This callback is passed to the interpreter code. It takes care of making
 * the initial invocation. */
static void toplevel_initial_invoke(MVMThreadContext *tc, void *data) {
    /* Create initial frame, which sets up all of the interpreter state also. */
    MVM_frame_invoke(tc, (MVMStaticFrame *)data, MVM_callsite_get_common(tc, MVM_CALLSITE_ID_NULL_ARGS), NULL, NULL, NULL, -1);
}

MVMCompUnit *cu;

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
}

void p6_run_code(char *code) {
    //const char *raw_clargs[1];
    const char **raw_clargs = malloc(sizeof(char*) * 1);
    const char *code_arg = malloc(strlen(code) + 1);
    strcpy(code_arg, code);
    instance->num_clargs = 1;
    raw_clargs[0] = code_arg;
    instance->raw_clargs = raw_clargs;
    instance->clargs = NULL;

    MVMThreadContext *tc = instance->main_thread;
    MVMStaticFrame *start_frame;

    start_frame = cu->body.main_frame ? cu->body.main_frame : cu->body.frames[0];
    MVM_interp_run(tc, &toplevel_initial_invoke, start_frame);
}

void p6_destroy() {
    MVM_vm_exit(instance);
}

END_OF_C

p6_initialize();
p6_run_code('say "Hello World from Perl6!";');
p6_run_code('say "Hello again!";');
p6_destroy();
