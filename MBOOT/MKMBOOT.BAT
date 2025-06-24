txtmsg sysign.txt sysign.msg
call binobj sysign.msg sysign sysign
l:\tp\tpc mbundo /m
bin2lnk.exe mbundo.exe mbundo mbundoexe
l:\bp\bin\tasm boot.ass
l:\bp\bin\tlink boot
exe2bin boot.exe boot.sys
bin2lnk.exe boot.sys bootsys bootsys
mkinh < mboot.ihs > mboot.inh
l:\tp\tpc mboot /m