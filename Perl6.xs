#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <moar.h>
#include "Perl6.h"

SV *(*call_method_callback)(IV, char *);
SV *(*eval_code_callback)(char *);
MVMInstance *instance;
MVMCompUnit *cu;
const char *filename = PERL6_INSTALL_PATH "/languages/perl6/runtime/perl6.moarvm";

PerlInterpreter *cur_my_perl;

static void toplevel_initial_invoke(MVMThreadContext *tc, void *data) {
    /* Create initial frame, which sets up all of the interpreter state also. */
    MVM_frame_invoke(tc, (MVMStaticFrame *)data, MVM_callsite_get_common(tc, MVM_CALLSITE_ID_NULL_ARGS), NULL, NULL, NULL, -1);
}

void init_callbacks(SV *(*eval_p6_code)(char *), SV *(*call_p6_method)(IV, char *)) {
    eval_code_callback = eval_p6_code;
    call_method_callback = call_p6_method;
}

SV *p5_int_to_sv(IV value) {
    PerlInterpreter * const my_perl = cur_my_perl;
    return newSViv(value);
}

SV *p5_float_to_sv(double value) {
    PerlInterpreter * const my_perl = cur_my_perl;
    return newSVnv((NV)value);
}

SV *p5_str_to_sv(char* value) {
    PerlInterpreter * const my_perl = cur_my_perl;
    SV * const sv = newSVpv(value, 0);
    SvUTF8_on(sv);
    return sv;
}

SV *p5_undef() {
    const PerlInterpreter *my_perl = cur_my_perl;
    return &PL_sv_undef;
}

char *library_location;

MODULE = Inline::Perl6		PACKAGE = Inline::Perl6		

void p6_setup_library_location(path)
        char *path
    CODE:
        library_location = path;

void
p6_initialize()
    CODE:
        const char  *lib_path[8];
        const char *raw_clargs[2];

        int argi         = 1;
        int lib_path_i   = 0;

        MVM_crash_on_error();

        instance   = MVM_vm_create_instance();
        lib_path[lib_path_i++] = PERL6_INSTALL_PATH "/languages/nqp/lib";
        lib_path[lib_path_i++] = PERL6_INSTALL_PATH "/languages/perl6/lib";
        lib_path[lib_path_i++] = PERL6_INSTALL_PATH "/languages/perl6/runtime";
        lib_path[lib_path_i++] = NULL;

        for( argi = 0; argi < lib_path_i; argi++)
            instance->lib_path[argi] = lib_path[argi];

        /* stash the rest of the raw command line args in the instance */
        instance->prog_name  = PERL6_INSTALL_PATH "/languages/perl6/runtime/perl6.moarvm";
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
        instance->num_clargs = 2;
        raw_clargs[0] = "inline.pl6";
        raw_clargs[1] = library_location;
        instance->raw_clargs = (char **)raw_clargs;
        instance->clargs = NULL; /* clear cache */

        MVMStaticFrame *start_frame;

        start_frame = cu->body.main_frame ? cu->body.main_frame : cu->body.frames[0];
        MVM_interp_run(tc, &toplevel_initial_invoke, start_frame);

        /* Points to the current opcode. */
        MVMuint8 *cur_op = NULL;

        /* The current frame's bytecode start. */
        MVMuint8 *bytecode_start = NULL;

        /* Points to the base of the current register set for the frame we
         * are presently in. */
        MVMRegister *reg_base = NULL;

        /* Stash addresses of current op, register base and SC deref base
         * in the TC; this will be used by anything that needs to switch
         * the current place we're interpreting. */
        tc->interp_cur_op         = &cur_op;
        tc->interp_bytecode_start = &bytecode_start;
        tc->interp_reg_base       = &reg_base;
        tc->interp_cu             = &cu;
        toplevel_initial_invoke(tc, cu->body.main_frame);

void
p6_destroy()
    CODE:
        MVM_vm_exit(instance);

SV *
p6_eval_code(code)
        char *code
    CODE:
        cur_my_perl = my_perl;
        RETVAL = eval_code_callback(code);
    OUTPUT:
        RETVAL

SV *
p6_call_method(name)
        char *name
    CODE:
        cur_my_perl = my_perl;
        RETVAL = call_method_callback(0, name);
    OUTPUT:
        RETVAL
