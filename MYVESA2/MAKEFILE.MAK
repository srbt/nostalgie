help:
        @echo Zkuste:
        @echo        make myvesa
        @echo        make showit

myvesa: egapal.obj myvesafr.obj
        tpc myvesa.pas /m /$G+

myvesafr.obj: myvesa.fra
        binobj myvesa.fra myvesafr.obj myvesaframe

myvesa.tpu: myvesa

egapal.obj: egapal.def
        binobj egapal.def egapal.obj egapaldef

egapal.def:
        getpal1

myvesa.fra:
        frames myvesa

showit: myvesa.tpu
        txtmsg defgroup.mss defgroup.msg
        binobj defgroup.msg defgroup defgroupmsg
        tpc showit.pas /m /$G+
