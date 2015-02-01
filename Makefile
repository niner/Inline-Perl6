.PHONY: clean test
all: lib/Inline/p6helper.so
clean:
	rm lib/Inline/p6helper.so
lib/Inline/p6helper.so: p6helper.c
	gcc -Wall p6helper.c `perl -MExtUtils::Embed -e ccopts -e ldopts` -shared -o lib/Inline/p6helper.so -fPIC -g -rdynamic
test:
	LD_PRELOAD=/home/nine/install/rakudo/install/lib/libmoar.so:/home/nine/Inline-Perl6/lib/Inline/p6helper.so gdb --args perl -Ilib test.pl
