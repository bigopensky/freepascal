/*
                At this entry point, most registers' values are unspecified, except:

   a1		Contains a function pointer to be registered with `atexit'.
		This is how the dynamic linker arranges to have DT_FINI
		functions called for shared libraries that have been loaded
		before this code runs.

   sp		The stack contains the arguments and environment:
		0(sp)			argc
		4(sp)			argv[0]
		...
		(4*argc)(sp)		NULL
		(4*(argc+1))(sp)	envp[0]
		...
					NULL
*/

	.text
	.globl _start
	.type _start,#function
_start:
	/* Clear the frame pointer since this is the outermost frame.  */
	mov fp, #0
	ldmia   sp!, {a2}

	/* Pop argc off the stack and save a pointer to argv */
	ldr ip,=operatingsystem_parameter_argc
	ldr a3,=operatingsystem_parameter_argv
	str a2,[ip]

	/* calc envp */
	add a2,a2,#1
	add a2,sp,a2,LSL #2
	ldr ip,=operatingsystem_parameter_envp

	str sp,[a3]
   	str a2,[ip]

        ldr     r1,=_etext                 /* Initialize gmon */
        ldr     r0,=_start
        bl      monstartup
        ldr     r0,=_mcleanup
        bl      atexit

        /* Save initial stackpointer */
	ldr ip,=__stkptr
	str sp,[ip]
	/* align sp again to 8 byte boundary, needed by eabi */
        sub sp,sp,#4

	/* Let the libc call main and exit with its return code.  */
	bl PASCALMAIN

	.globl  _haltproc
    .type   _haltproc,#function
_haltproc:
        /* r0 contains exitcode */
	swi 0x900001
	b _haltproc

	/* Define a symbol for the first piece of initialized data.  */
	.data
	.globl __data_start
__data_start:
	.long 0
	.weak data_start
	data_start = __data_start

.bss
        .comm __stkptr,4

        .comm operatingsystem_parameter_envp,4
        .comm operatingsystem_parameter_argc,4
        .comm operatingsystem_parameter_argv,4

	.section ".comment"
	.byte 0
	.ascii "generated by FPC http://www.freepascal.org\0"

/* We need this stuff to make gdb behave itself, otherwise
   gdb will chokes with SIGILL when trying to debug apps.
*/
        .section ".note.ABI-tag", "a"
        .align 4
        .long 1f - 0f
        .long 3f - 2f
        .long  1
0:      .asciz "GNU"
1:      .align 4
2:      .long 0
        .long 2,0,0
3:      .align 4

