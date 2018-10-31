#Lucian Jiang-Wei
#Read a machine code binary file, and disassemble back into MIPs code

#Procedure: get file name from user, convert binary characters to integer, convert binary opcode to decimal, convert the rest of the fields to decimal acoording to opcode, use opcode
#lookup instruction name in table, use converted fields to look up register names in table, print and repeat until end of file is reached
#Author: Lucian Jiang-Wei
#I/O User enters filename, data is read from the file, output is the disassembled MIPs code

.data
regs:  .asciiz "$zero   ", "$at     ", "$v0     ", "$v1     ", "$a0     ", "$a1     ", "$a2     ", "$a3     ", "$t0     ", "$t1     ", "$t2     ", "$t3     ", "$t4     ", "$t5     ", "$t6     ", "$t7     ", "$s0     ", "$s1     ", "$s2     ", "$s3     ", "$s4     ", "$s5     ", "$s6     ", "$s7     ", "$t8     ", "$t9     ", "$k0     ", "$k1     ", "$gp     ", "$sp     ", "$fp     ", "$ra     "
fregs: .asciiz "$f0     ", "$f1     ", "$f2     ", "$f3     ", "$f4     ", "$f5     ", "$f6     ", "$f7     ", "$f8     ", "$f9     ", "$f10    ", "$f11    ", "$f12    ", "$f13    ", "$f14    ", "$f15    ", "$f16    ", "$f17    ", "$f18    ", "$f19    ", "$f20    ", "$f21    ", "$f22    ", "$f23    ", "$f24    ", "$f25    ", "$f26    ", "$f27    ", "$f28    ", "$f29    ", "$f30    ", "$f31    "
rtypelabel: .asciiz "R-Type: "
rtype: .space 32
itype: .asciiz "I-Type: "
op: .asciiz    "invld op", "invld op", "j       ", "jal     ", "beq     ", "bne     ", "blez    ", "bgtz    ", "addi    ", "addiu   ", "slti    ", "sltiu   ", "andi    ", "ori     ", "xori    ", "lui     ", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op", "invld op",
               "lb      ", "lh      ", "lwl     ", "lw      ", "lbu     ", "lhu     ", "lwr     ", "invld op", "sb      ", "sh      ", "swl     ", "sw      ", "invld op", "invld op", "swr     ", "cache   ", "ll      ", "lwc1    ", "lwc2    ", "pref    ", "invld op", "ldc1    ", "ldc2    ", "invld op", "sc      ", "swc1    ", "swc2    ", "invld op", "invld op", "sdc1    ", "sdc2    ", "invld op"
funct: .asciiz "sll     ", "no funct", "srl     ", "sra     ", "sllv    ", "no funct", "srlv    ", "srav    ", "jr      ", "jalr    ", "movz    ", "movn    ", "syscall ", "break   ", "no funct", "sync    ", "mfhi    ", "mthi    ", "mflo    ", "mtlo    ", "no funct", "no funct", "no funct", "no funct", "mult    ", "multu   ", "div     ", "divu    ", "no funct", "no funct", "no funct", "no funct",
	       "add     ", "addu    ", "sub     ", "subu    ", "and     ", "or      ", "xor     ", "nor     ", "no funct", "no funct", "slt     ", "sltu    ", "no funct", "no funct", "no funct", "no funct", "tge     ", "tgeu    ", "tlt     ", "tltu    ", "teq     ", "no funct", "tne     ", "no funct", "no funct"
floatfunct: .asciiz "add.s    ", "sub.s    ", "mul.s    ", "div.s    ", "sqrt.s   ", "abs.s    ", "mov.s    ", "neg.s    ", "no funct ", "no funct ", "no funct ", "no funct ", "round.w.s", "trunc.w.s", "ceil.w.s ", "floor.w.s", "no funct ", "no funct ", "movz.s   ", "movn.s   ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ",
                    "no funct ", "no funct ", "no funct ", "cvt.s.d  ", "cvt.d.s  ", "no funct ", "no funct ", "cvt.w.s  ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "no funct ", "c.f.s    ", "c.un.s   ", "c.eq.s   ", "c.ueq.s  ", "c.olt.s  ", "c.ult.s  ", "c.ole.s  ", "c.ule.s  ", "c.sf.s   ", "c.ngle.s ",
                    "c.seq.s  ", "c.ngl.s  ", "c.lt.s   ", "c.nge.s  ", "c.le.s   ", "c.ngt.f  "
negative: .asciiz "-"
comma: .asciiz ", "
prompt: .asciiz "Enter a file name: \n"
newline: .asciiz "\n"
.align 2
buffer: .space 4096
filename: .space 32
num: .space 4096

.text
#get filename from user
  	#prompt user for input
	la $a0, prompt #load address of message
	li $v0, 4 #syscall for print string
	syscall
	
	#store input in string
	la $a0, filename #load address of place to store string
	li $a1, 32 #string size in bytes
	move $s0, $a0 #save input in s0
	li $v0, 8 #syscall function to read string
	syscall
#remove newine smbol from file and replace with null terminator
removeChar:
	li $t0, 0 #loop start value
	li $t1, 32 #loops end value
removeLoop:
	beq $t0, $t1, removeDone #dont branch until endvalue is met
	lb $t3, filename($t0) #load the string
	bne $t3, 0xa, removeCounter #if the end character is not reached, branch to counter
	sb $zero, filename($t0) #replace null terminator with string end character
removeCounter:
	addi $t0, $t0, 1 #increment loop by 1
	j removeLoop
removeDone:
    
    #read and store data
    #open a file for reading
	li   $v0, 13       # system call for open file
	la   $a0, filename      # load file name
	li   $a1, 0        # set syscall to read file
	li   $a2, 0
	syscall            # save file descriptor in $v0
	move $s5, $v0      # save the file descriptor for later use

    #read from file
  	li   $v0, 14       # system call for read from file
 	move $a0, $s5      # file descriptor 
	la   $a1, buffer   # address of buffer to which to read
	li   $a2, 4096	   # hardcoded buffer length
	syscall            # read from file
	
	#close file
	li $v0, 16 #close file syscal number
	move $a0, $s6 #get rid of file descriptor
	syscall
	
#convert the data read from file to an integer
atoi:
	#set all temporary values to 0 to sanitize data
	li $t5, 0
	li $t2, 0
	li $s6, 0
	li $t8, 0
loop:
	lb $t0, buffer($t5) #load in the data read from the file
	beq $t0, $zero, testop #done if null terminator is hit
	blt $t0, 48, skip   #check if char is not a digit (ascii<'0')
        bgt $t0, 57, skip   #check if char is not a digit (ascii>'0')
	subi $t0, $t0, 48 #subtract by 48 to convert to decimal
	addi $t5, $t5, 1 #increment loop
	sb $t0, num($s6) #save converted integer to array
	addi $s6, $s6, 1 #increment array
	j loop
skip:
	addi $t5, $t5, 1 #increment loop
	j loop

testop:
	move $s7, $s6 #save file length
	li $s6, 0 #set counter to 0
	j opcode
#set default values	
opcode:
	li $t3, 6
	li $t2, 1
	li $t8, 0
	li $t9, 5
	li $s1, 0
#convert binary segement to integer
oploop:
	lb $t1, num($s6) #load byte to register t1
	beq $t3, 0, type #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t1, $t2 #multiple the result
	add $s1, $s1, $t8 #sum up result
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j oploop
#skip if instruction does not have a rt fiels
skiprt:
	li $t6, 1
	li $t4, 0
	j rsprep
#skip if instruction does not have rs field
skiprs:
	li $t7, 1
	li $t4, 0
	j rsprep
#tell program that this is a r-type instruction
rsreg: 
	li $t5, 1
	j rsprep
#load in default values
rsprep:
	li $t2, 1
	li $t3, 5
	li $t8, 0
	li $t9, 4
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
rsloop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 0, printrs #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j rsloop
#print out recently converted segement of data
printrs:
	#branch if skipping rs
	beq $t7, 1, rtprep
	#branch if printing rt field is first in instruction
	beq $t4, 1, rtfirst
	#save value for later if r-type instruction
	beq $t5, 1, savers
	
	#look up value and print from table
	li $t5, 9
	mul $t5, $t5, $t1
	la $a0, regs($t5)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	beq $t4, 1, rssecond
	
	j rtprep

savers:
	#save value for later if r-type instruction
	sb $t1, rtype($s3)
	addi $s3, $s3, 1
	li $t5, 1
	j rtprep
#skip both rt and rs
rtrsskip:
	li $t7, 0
	li $t6, 0
	li $t5, 0
	li $t4, 0
	j immedprep
#print rs second if it comes second in instruction
rssecond:
	#look up value from table and print
	li $t5, 9
	mul $t5, $t5, $s2
	la $a0, regs($t5)
	li $v0, 4
	syscall
	
	j immedprep
#save value for later if rt comes first in instruction
rtfirst:
	move $s2, $t1
	j rtprep
#set default values	
rtprep:
	li $t2, 1
	li $t3, 5
	li $t8, 0
	li $t9, 4
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
rtloop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 0, printrt #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j rtloop
#print out recently converted segement of data
printrt:
	#skip print rt
	beq $t6, 1, rtrsskip
	#save value for later if r-type instruction
	beq $t5, 1, savert

	#look up value and print from table
	li $t5, 9
	mul $t5, $t5, $t1
	la $a0, regs($t5)
	li $v0, 4
	syscall
	
	#skip printing if no rt rs fields
	beq $t7, 1, rtrsskip
	
	la $a0, comma
	li $v0, 4
	syscall
	
	#go back to print rs field if skipped before
	beq $t4, 1, rssecond
	
	#branch if i type
	j immedprep
#save value for later if r-type instruction
savert:
	sb $t1, rtype($s3)
	addi $s3, $s3, 1
	li $t5, 1
	j rdprep
#set default values	
rdprep:
	li $t2, 1
	li $t3, 5
	li $t8, 0
	li $t9, 4
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
rdloop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 0, saverd #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j rdloop
#print out recently converted segement of data
saverd:
	sb $t1, rtype($s3)
	addi $s3, $s3, 1
	#go to print shamt function
	j shamtprep
#set default values
shamtprep:
	li $t2, 1
	li $t3, 5
	li $t8, 0
	li $t9, 4
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
shamtloop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 0, saveshamt #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j shamtloop
#save value for later if r-type instruction
saveshamt:
	sb $t1, rtype($s3)
	addi $s3, $s3, 1
	#go to save func function
	j funcprep
#set default values
funcprep:
	li $t2, 1
	li $t3, 6
	li $t8, 0
	li $t9, 5
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
funcloop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 0, savefunc #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j funcloop
#save value for later if r-type instruction
savefunc:
	sb $t1, rtype($s3)
	
	#branch if it is a floating point instruction
	beq $s4, 1, printfpr
	
	#go to print r-type instruction
	j printreg
#set default values
immedprep:
	li $t2, 1
	li $t3, 16
	li $t8, 0
	li $t9, 15
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
immedloop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 16, checksigbit
	beq $t3, 0, printimmed #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	#increment/ decrement specific counters
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j immedloop
#check to see if sign is negative
checksigbit:
	lb $t6, num($s6)
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	add $s6, $s6, 1
	#branch back if sign is 0
	beq $t6, 0, immedloop
	
	la $a0, comma
	li $v0, 4
	syscall
	#print negativ sign
	la $a0, negative
	li $v0, 4
	syscall
	#copy values for temp use
	move $t7, $t3
	move $t4, $s6
#flip the bits to convert to unsigned binary
twostobinaryloop:
	beq $t7, 0, addone #branch after all bits are flipped
	lb $t6, num($t4) #load bits and flip them
	beq $t6, 0, zerotoone
	beq $t6, 1, onetozero
zerotoone:
	li $t6, 1
	sb $t6, num($t4)
	add $t4, $t4, 1
	sub $t7, $t7, 1
	j twostobinaryloop
onetozero:
	li $t6, 0
	sb $t6, num($t4)
	add $t4, $t4, 1
	sub $t7, $t7, 1
	j twostobinaryloop
#add one to convert twos complement numbers to unsigned
addone:
	sub $t4, $t4, 1
	lb $t6, num($t4) #load bit
	beq $t6, 0, iszero #branch if zero
	li $t6, 0 #replace 1 with zero to shift it along
	sb $t6, num($t4)
	j addone
iszero:
	li $t6, 1 #replace 1 with zero for binary addition
	sb $t6, num($t4)
	j immedloop
#print out recently converted segement of data
printimmed:
	beq $t6, 1, nocomma #skip printing comma if negativ sign is already printed
	
	la $a0, comma
	li $v0, 4
	syscall
nocomma:
	move $a0, $t1
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	#check if rof is reached
	j isdone
#determine the type of instruction based on the opcode, branch accordingly
type:
	beq $s1, 0, reg
	beq $s1, 2, jump
	beq $s1, 3, jump
	beq $s1, 17, fpr
	bgt $s1, 4, int
#branch here if r type value	
reg:
	li $t4, 0
	li $t6, 0
	li $t7, 0
	li $s3, 0
	li $s4, 0
	#jump to print rs function
	j rsreg
printreg:
	move $t1, $s3
	lb $t2, rtype($t1)
	
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, funct($t0)
	li $v0, 4
	syscall
	
	#branch based on instruction format
	ble $t2, 3, printrdrtshamt
	ble $t2, 7, printrdrtrs
	beq $t2, 9, printrdrs
	beq $t2, 8, printrsreg
	beq $t2, 17, printrsreg
	beq $t2, 19, printrsreg
	beq $t2, 12, printnewline
	beq $t2, 13, printnewline
	beq $t2, 15, printnewline
	beq $t2, 16, printrd
	beq $t2, 18, printrd
	beq $t2, 24, printrsrt
	beq $t2, 25, printrsrt
	beq $t2, 26, printrsrt
	beq $t2, 27, printrsrt
	bge $t2, 48, printrsrt
	bge $t2, 32, printrdrsrt
	
	j isdone
#print instructions in rd, rt, shamt format	
printrdrtshamt:
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 1
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 3
	lb $a0, rtype($t1)
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in rd, rt, rs format
printrdrtrs:
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 1
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 0
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in rd, rs
printrdrs:
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 0
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in rs format
printrsreg: 
	#load offset of data
	li $t1, 0
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in rd format
printrd:
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in rs, rt format
printrsrt:
	
	#load offset of data
	li $t1, 0
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	
	#load offset of data
	li $t1, 1
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in rd, rs, rt format
printrdrsrt:
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 0
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	
	#load offset of data
	li $t1, 1
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print new line
printnewline:
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#floating-point instructions
fpr:
	#reset temp values
	li $t4, 0
	li $t6, 0
	li $t7, 0
	li $s3, 0
	li $s4, 1
	#jump to convert rs function
	j rsreg
#print floating point instructions
printfpr:
	#load data
	move $t1, $s3
	lb $t2, rtype($t1)
	
	#look up table offset and print
	li $t0, 10
	mul $t0, $t0, $t2
	la $a0, floatfunct($t0)
	li $v0, 4
	syscall
	
	#branch based on instruction format
	ble $t2, 3, printfdfsft
	beq $t2, 18, printfdfsrt
	beq $t2, 19, printfdfsrt
	beq $t2, 50, printfdfs
	beq $t2, 60, printfdfs
	beq $t2, 62, printfdfs
	bge $t2, 48, printnewline
	bge $t2, 4, printfdfs
	
	j isdone
#print instructions in fd, fs, ft format
printfdfsft:
	#load offset of data
	li $t1, 3
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	
	#load offset of data
	li $t1, 1
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in fd, fs, rt format
printfdfsrt:
	#load offset of data
	li $t1, 3
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	
	#load offset of data
	li $t1, 1
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, regs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#print instructions in fd, fs format
printfdfs:
	#load offset of data
	li $t1, 3
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, comma
	li $v0, 4
	syscall
	#load offset of data
	li $t1, 2
	lb $t2, rtype($t1)
	
	#shift to the location of the register string and print
	li $t0, 9
	mul $t0, $t0, $t2
	la $a0, fregs($t0)
	li $v0, 4
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	
	j isdone
#branch here if I-Type instruction
int:
	#print opcode
	li $t0, 9
	mul $t0, $t0, $s1
	#look up table offset and print string
	la $a0, op($t0)
	li $v0, 4
	syscall
	#reset temp values
	li $t4, 1
	li $t5, 0
	li $t6, 0
	li $t7, 0
	li $s4, 0
	
	#branch based on instruction format
	beq $s1, 6, skiprt
	beq $s1, 7, skiprt
	beq $s1, 15, skiprs
	beq $s1, 47, printnewline
	bgt $s1, 7, rsprep
	li $t4, 0
	
	#jump to convert rs function
	j rsprep
jump:
	#print opcode
	li $t0, 9
	mul $t0, $t0, $s1
	
	#look up table offset and print string
	la $a0, op($t0)
	li $v0, 4
	syscall
	
	#load in default values
	li $t2, 1
	li $t3, 26
	li $t8, 0
	li $t9, 25
	li $t1, 0
	li $t0, 0
#convert binary segement to integer
jumploop:
	lb $t0, num($s6) #load byte to register t1
	beq $t3, 0, printjump #branch once counter hits 0
	sllv $t2, $t2, $t9 #shift left depending on bit position
	mul $t8, $t0, $t2 #multiple the result
	add $t1, $t1, $t8 #sum up result
	#increment/ decrement specific counters
	
	add $s6, $s6, 1
	sub $t3, $t3, 1
	sub $t9, $t9, 1
	li $t2, 1
	j jumploop
printjump:
	#print address
	move $a0, $t1
	li $v0, 1
	syscall
	
	la $a0, newline
	li $v0, 4
	syscall
	#check if program is done
	j isdone
isdone:
	#branch to done if the counter matches the length of filesize
	beq $s6, $s7, done
	beq $s7, 0, done
	#jump to load in next opcode
	j opcode
done:
	li $v0, 10 #syscall exit program function
	syscall
