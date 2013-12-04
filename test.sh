#!/bin/sh

clang dispatch_test.c -I/usr/local/include/dispatch -L/usr/local/lib -ldispatch -I$GNUSTEP_SYSTEM_ROOT/Library/Headers -L$GNUSTEP_SYSTEM_ROOT/Library/Libraries -I$GNUSTEP_LOCAL_ROOT/Library/Headers -L$GNUSTEP_LOCAL_ROOT/Library/Libraries -lobjc -o dispatch_test
./dispatch_test
