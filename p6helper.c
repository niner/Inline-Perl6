#include <EXTERN.h>
#include <perl.h>

SV *(*call_method_callback)(IV, char *);

void init_call_method(SV *(*call_p6_method)(IV, char *)) {
    call_method_callback = call_p6_method;
}
