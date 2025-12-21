
.ORG 0
NOT R1     #R1 = FFFF ,
NOP            #No change
NOP            #No change
NOP            #No change
NOP            #No change
INC R1     #R1 =00000 ,
IN R1	       #R1= 000E, add E on the in port
IN R2          #R2= 0010, add 10 on the in port
NOP
NOP
NOP
Nop
NOT R2     #R2= FFEF,
INC R1     #R1= 000F,
LDM R3, 0005
NOP
NOP
NOP
Nop
sub R2, R2, R3    #R2= FFEA,  //R2 - R3
OUT R1
OUT R2