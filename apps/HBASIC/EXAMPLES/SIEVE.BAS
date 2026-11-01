rem next line turns overflow, array checks and line numbers off
rem $option a-o-n-
defint a-z
10 PRINT "BYTE SIEVE, 7000 numbers done 5 times"
 t!=timer
20 SIZE=7000
30 DIM FLAGS(7001)
   for j=1 to 5
40 ACOUNT=0
50 FOR I=0 TO SIZE
60 FLAGS(I)=1
70 NEXT I
80 FOR I=0 TO SIZE
90 IF FLAGS(I)=0 THEN GOTO 170
100 PRIME=I+I+3
110 K=I+PRIME
120 IF K>SIZE THEN GOTO 160
130 FLAGS(K)=0
140 K=K+PRIME
150 GOTO 120
160 ACOUNT=ACOUNT+1
170 NEXT I
    next j
t!=timer-t!
180 PRINT ACOUNT;"primes found"
print "Took" t!/5 "seconds"
