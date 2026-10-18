REM retail.bat
REM
sed s/=RETAIL=0/=RETAIL=1/ makefile >makefile.ret
make clean
make -f makefile.ret
call cpm

