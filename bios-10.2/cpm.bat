REM
echo  Create a new ROM binary with CP/M-68
REM
set TARGET=bios10
REM
make %TARGET%.bin
copy/b %TARGET%.bin+rom\rom80.bin cpm68sm.bin
copy/b %TARGET%.bin+rom\rom400.bin cpm68.bin

