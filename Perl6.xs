#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <moar.h>
#include "Perl6.h"

void (*p5_callback)(PerlInterpreter *);
SV *(*call_method_callback)(IV, char *);
SV *(*call_function_callback)(char *, SV *args);
SV *(*eval_code_callback)(char *);
MVMInstance *instance;
MVMCompUnit *cu;
const char *filename = PERL6_INSTALL_PATH "/languages/perl6/runtime/perl6.moarvm";

static void toplevel_initial_invoke(MVMThreadContext *tc, void *data) {
    /* Create initial frame, which sets up all of the interpreter state also. */
    MVM_frame_invoke(tc, (MVMStaticFrame *)data, MVM_callsite_get_common(tc, MVM_CALLSITE_ID_NULL_ARGS), NULL, NULL, NULL, -1);
}

void init_p5_callback(void (*new_p5_callback)(PerlInterpreter *)) {
    p5_callback = new_p5_callback;
}

void init_callbacks(SV *(*eval_p6_code)(char *), SV *(*call_p6_method)(IV, char *), SV *(*call_p6_function)(char *, SV *)) {
    eval_code_callback = eval_p6_code;
    call_method_callback = call_p6_method;
    call_function_callback = call_p6_function;
}

U32 p5_SvIOK(PerlInterpreter *my_perl, SV* sv) {
    return SvIOK(sv);
}

U32 p5_SvNOK(PerlInterpreter *my_perl, SV* sv) {
    return SvNOK(sv);
}

U32 p5_SvPOK(PerlInterpreter *my_perl, SV* sv) {
    return SvPOK(sv);
}

U32 p5_sv_utf8(PerlInterpreter *my_perl, SV* sv) {
    if (SvUTF8(sv)) { // UTF-8 flag set -> can use string as-is
        return 1;
    }
    else { // pure 7 bit ASCII is valid UTF-8 as well
        STRLEN len;
        char * const pv  = SvPV(sv, len);
        STRLEN i;
        for (i = 0; i < len; i++)
            if (pv[i] < 0) // signed char!
                return 0;
        return 1;
    }
}

IV p5_sv_iv(PerlInterpreter *my_perl, SV* sv) {
    return SvIV(sv);
}

double p5_sv_nv(PerlInterpreter *my_perl, SV* sv) {
    return (double)SvNV(sv);
}

int p5_is_object(PerlInterpreter *my_perl, SV* sv) {
    return sv_isobject(sv);
}

int p5_is_sub_ref(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVCV);
}

int p5_is_array(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVAV);
}

int p5_is_hash(PerlInterpreter *my_perl, SV* sv) {
    return (SvROK(sv) && SvTYPE(SvRV(sv)) == SVt_PVHV);
}

int p5_is_undef(PerlInterpreter *my_perl, SV* sv) {
    return !SvOK(sv);
}

AV *p5_sv_to_av(PerlInterpreter *my_perl, SV* sv) {
    return (AV *) SvRV(sv);
}

HV *p5_sv_to_hv(PerlInterpreter *my_perl, SV* sv) {
    return (HV *) SvRV(sv);
}

char *p5_sv_to_char_star(PerlInterpreter *my_perl, SV *sv) {
    STRLEN len;
    char * const pv  = SvPV(sv, len);
    return pv;
}

STRLEN p5_sv_to_buf(PerlInterpreter *my_perl, SV *sv, char **buf) {
    STRLEN len;
    *buf  = SvPV(sv, len);
    return len;
}

void p5_sv_refcnt_dec(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_dec(sv);
}

void p5_sv_refcnt_inc(PerlInterpreter *my_perl, SV *sv) {
    SvREFCNT_inc(sv);
}

SV *p5_int_to_sv(PerlInterpreter *my_perl, IV value) {
    return newSViv(value);
}

SV *p5_float_to_sv(PerlInterpreter *my_perl, double value) {
    return newSVnv((NV)value);
}

SV *p5_str_to_sv(PerlInterpreter *my_perl, char* value) {
    SV * const sv = newSVpv(value, 0);
    SvUTF8_on(sv);
    return sv;
}

SV *p5_buf_to_sv(PerlInterpreter *my_perl, STRLEN len, char* value) {
    SV * const sv = newSVpv(value, len);
    return sv;
}

I32 p5_av_top_index(PerlInterpreter *my_perl, AV *av) {
    return av_top_index(av);
}

SV *p5_av_fetch(PerlInterpreter *my_perl, AV *av, I32 key) {
    SV ** const item = av_fetch(av, key, 0);
    if (item)
        return *item;
    return NULL;
}

void p5_av_push(PerlInterpreter *my_perl, AV *av, SV *sv) {
    av_push(av, sv);
}

I32 p5_hv_iterinit(PerlInterpreter *my_perl, HV *hv) {
    return hv_iterinit(hv);
}

HE *p5_hv_iternext(PerlInterpreter *my_perl, HV *hv) {
    return hv_iternext(hv);
}

SV *p5_hv_iterkeysv(PerlInterpreter *my_perl, HE *entry) {
    return hv_iterkeysv(entry);
}

SV *p5_hv_iterval(PerlInterpreter *my_perl, HV *hv, HE *entry) {
    return hv_iterval(hv, entry);
}

void p5_hv_store(PerlInterpreter *my_perl, HV *hv, const char *key, SV *val) {
    hv_store(hv, key, strlen(key), val, 0);
}

SV *p5_undef(PerlInterpreter *my_perl) {
    return &PL_sv_undef;
}

HV *p5_newHV(PerlInterpreter *my_perl) {
    return newHV();
}

AV *p5_newAV(PerlInterpreter *my_perl) {
    return newAV();
}

SV *p5_newRV_noinc(PerlInterpreter *my_perl, SV *sv) {
    return newRV_noinc(sv);
}

const char *p5_sv_reftype(PerlInterpreter *my_perl, SV *sv) {
    return sv_reftype(SvRV(sv), 1);
}

SV *p5_eval_pv(PerlInterpreter *my_perl, const char* p, I32 croak_on_error) {
    PERL_SET_CONTEXT(my_perl);
    return eval_pv(p, croak_on_error);
}

SV *p5_err_sv(PerlInterpreter *my_perl) {
    return ERRSV;
}

char *library_location;

MODULE = Inline::Perl6		PACKAGE = Inline::Perl6		

void setup_library_location(path)
        char *path
    CODE:
        library_location = path;

void
initialize()
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

        p5_callback(my_perl);

void
destroy()
    CODE:
        MVM_vm_destroy_instance(instance);

SV *
run(code)
        char *code
    CODE:
        RETVAL = eval_code_callback(code);
    OUTPUT:
        RETVAL

SV *
call(name, ...)
        char *name
    CODE:
        AV * args = newAV();
        av_extend(args, items - 1);
        int i;
        for (i = 0; i < items - 1; i++) {
            SV * const next = SvREFCNT_inc(ST(i + 1));
            if (av_store(args, i, next) == NULL)
                SvREFCNT_dec(next); /* see perlguts Working with AVs */
        }

        RETVAL = call_function_callback(name, newRV_noinc((SV *) args));
    OUTPUT:
        RETVAL

SV *
invoke(name)
        char *name
    CODE:
        RETVAL = call_method_callback(0, name);
    OUTPUT:
        RETVAL
