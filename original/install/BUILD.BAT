@echo off
copy ..\folder.exe data\folder.exe
copy ..\help\ff98.hlp data\folder.hlp
copy ..\help\ff98.cnt data\folder.cnt
copy ..\docdll.dll data\docdll.dll
del data.z
icomp -i data\*.* data.z
copy data.z disk
cd setup
compile setup.rul
copy setup.ins ..\disk
packlist setup.lst
copy setup.pkg ..\disk
cd ..

