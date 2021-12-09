extrn  GetStdHandle: proc, 
       WriteConsoleA: proc, 
	   ReadConsoleA: proc,
	   ReadConsoleA: proc,
       ExitProcess: proc,
	   lstrlenA: proc
	  	   
STACKALLOC macro arg 
	push R15 
	mov R15, RSP 
	sub RSP, 8*4 
	if arg  
		sub RSP, 8*arg
	endif
	and SPL, 0F0h  
endm

STACKFREE macro arg 
	mov RSP, R15
	pop R15
endm

NULL_FIFTH_ARG macro arg
	mov qword ptr [RSP + 32], 0
endm

.data
	STD_OUTPUT_HANDLE= -11 
	STD_INPUT_HANDLE = -10 
	hStdInput qword ?
	hStdOutput qword ?
	result qword 0
	const1 db 'Enter A: ', 0
	const2 db 'Enter B: ', 0
	result_message db '2569h - (12h + A + B) = ', 0
	invalid_char_exception db 'Character aren`t readable.', 0 
	finish db 0Ah, 'Operation completed.', 0 
	error_message db 0Ah, 'Error!', 0 
	stroka db '2569h - (12h + %s + %s)', 0


.code 
	Start proc
		STACKALLOC 
		mov RCX, STD_OUTPUT_HANDLE 
		call GetStdHandle 
		mov hStdOutput, RAX 

		mov RCX, STD_INPUT_HANDLE
		call GetStdHandle
		mov hStdInput, RAX 

		lea RAX, const1
		push RAX
		call PrintString
		call ReadSignedFromString 
		cmp R10, 0
		jnz M1

		char_exception:
			lea RAX, invalid_char_exception 
			push RAX 
			call PrintString
			jmp final 

		error:
			lea RAX, error_message 
			push RAX 
			call PrintString
			jmp final

		M1:
			cmp RAX, -32767
			jl error ; Если число меньше -32767, то ошибка.
			cmp RAX, 32767
			jg error ; Если число больше 32767, то тоже ошибка.
			mov R8, RAX ; Положим число A в RAX.
			add R8, 12h  ; Прибавим к A константу 12h. Пока получаем выражение const2 + A
			push R8

		lea RAX, const2 
		push RAX 
		call PrintString
		call ReadSignedFromString 
		cmp R10, 0
		jnz M2 
		lea RAX, invalid_char_exception 
		push RAX 
		call PrintString
		jmp final

		M2:
			cmp RAX, -32767
			jl error
			cmp RAX, 32767
			jg error
			pop R8
			add R8, RAX ; Добавляем к выражению const2 + A число B, получаем: const2 + A + B.
			neg R8 ; Умножаем (const2 + A + B) на минус один.
			add R8, 2569h ; Доблавяем к выражению const 1
			mov result, R8

		lea RAX, result_message 
		push RAX
		call PrintString
		push result

		call PrintSigned

		final:
		xor RCX, RCX

		call ExitProcess 

	Start endp


	PrintString proc uses RAX RCX RDX R8 R9 R10 R11,
	string: qword
		local bytesWritten: qword
		STACKALLOC 1
		mov RCX, string
		call lstrlenA

		mov RCX, hStdOutput
		mov RDX, string
		mov R8, RAX
		lea R9, bytesWritten

		NULL_FIFTH_ARG
		call WriteConsoleA
		STACKFREE
		ret 8
	PrintString endp

	ReadSignedFromString proc uses RBX RCX RDX R8 R9
		local readStr[64]: byte,  bytesRead: dword
		STACKALLOC 2
		mov RCX, hStdInput
		lea RDX, readStr
		mov R8, 64
		lea R9, bytesRead
		NULL_FIFTH_ARG

		call ReadConsoleA
		xor RCX, RCX
		mov ECX, bytesRead 
		sub ECX, 2
		mov readStr[RCX], 0 
		xor RBX, RBX
		mov R8, 1 

		pass:
			dec RCX 
			cmp RCX, -1 
			jz scan_finish
			xor RAX, RAX 
			mov AL, readStr[RCX] 
			cmp AL, '-'
			jne eval
			neg RBX 
			jmp scan_finish 

		eval:
			cmp AL, 30h
			jl error
			cmp AL, 39h
			jg error 

		sub RAX, 30h
		mul R8
		add RBX, RAX
		mov RAX, 10
		mul R8
		mov R8, RAX
		jmp pass 
		error: 
			mov R10, 0 
			STACKFREE 
			ret 

		scan_finish: 
			mov R10, 1 
			mov RAX, RBX 
			STACKFREE 
			ret 
	ReadSignedFromString endp

	PrintSigned proc uses RAX RCX RDX R8 R9 R10 R11,
		number: qword 
		local numberStr[22]: byte 
		xor R8, R8 
		mov RAX, number

		cmp number, 0 
		jg next 
		mov numberStr[R8], '-' 
		inc R8 
		neg RAX

		next:
			mov RBX, 10 
			xor RCX, RCX 
			division: 
			xor RDX, RDX 
			div RBX 
			add RDX, 30h 
			push RDX 
			inc RCX 
			cmp RAX, 0 
			jnz division 

		transfer: 
		pop RDX
		mov numberStr[R8], DL
		inc R8
		loop transfer

		mov numberStr[R8], 0 
		lea RAX, numberStr
		push RAX 
		call PrintString
		STACKFREE
		ret 8 
	PrintSigned endp

end
