CLO
BIJ 0       
JMP b1_check
BOS 0       
b0_wait:
BIJ 0       
JMP 000     
JMP b0_wait 
b2_check:
BIJ 1       
JMP b2_check
BOS 1       
b1_wait:
BIJ 1       
JMP 000     
JMP b1_wait    
b2_check:
BIJ 2       
JMP b3_check    
BOS 2       
b2_wait:
BIJ 2       
JMP 000     
JMP b2_wait    
b3_check:
BIJ 3       
JMP 000     
BOS 3       
b3_wait:
BIJ 3       
JMP 000     
JMP b3_wait     