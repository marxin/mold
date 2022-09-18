#!/bin/bash
export LC_ALL=C
set -e
CC="${TEST_CC:-cc}"
CXX="${TEST_CXX:-c++}"
GCC="${TEST_GCC:-gcc}"
GXX="${TEST_GXX:-g++}"
OBJDUMP="${OBJDUMP:-objdump}"
MACHINE="${MACHINE:-$(uname -m)}"
testname=$(basename "$0" .sh)
echo -n "Testing $testname ... "
t=out/test/elf/$MACHINE/$testname
mkdir -p $t

if [ $MACHINE = x86_64 -o $MACHINE = i386 -o $MACHINE = i686 ]; then
  mtls=-mtls-dialect=gnu
elif [ $MACHINE = aarch64 ]; then
  mtls=-mtls-dialect=trad
elif [ $MACHINE != riscv* ] && [ $MACHINE != sparc64 ]; then
  echo skipped
  exit
fi

cat <<EOF | $GCC $mtls -c -o $t/a.o -xc -
#include <stdio.h>

extern _Thread_local int foo;
static _Thread_local int bar;

int *get_foo_addr() { return &foo; }
int *get_bar_addr() { return &bar; }

int main() {
  foo = 3;
  bar = 5;

  printf("%d %d %d %d\n", *get_foo_addr(), *get_bar_addr(), foo, bar);
  return 0;
}
EOF

cat <<EOF | $CC -xc -c -o $t/b.o -
_Thread_local int foo;
EOF

$CC -B. -o $t/exe $t/a.o $t/b.o
$QEMU $t/exe | grep -q '3 5 3 5'

echo OK
