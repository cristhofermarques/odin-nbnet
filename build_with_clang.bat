@echo off

clang -c nbnet.c -o nbnet.obj -O2 -std=c99
llvm-lib nbnet.obj

del nbnet.obj
move nbnet.lib binaries\nbnet_windows_amd64.lib

clang -c nbnet.c -o nbnet_log.obj -O2 -std=c99 -DNBNET_LOG=1
llvm-lib nbnet_log.obj

del nbnet_log.obj
move nbnet_log.lib binaries\nbnet_windows_amd64_log.lib