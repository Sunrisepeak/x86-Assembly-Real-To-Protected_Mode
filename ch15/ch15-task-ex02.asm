         ;代码清单15-2
         ;文件名：c15.asm
         ;文件说明：用户程序 
         ;创建日期：2011-11-15 19:11   

;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         
         head_len         dd header_end           ;程序头部的长度#0x04

         stack_seg        dd 0                    ;用于接收堆栈段选择子#0x08
         stack_len        dd 1                    ;程序建议的堆栈大小#0x0c
                                                  ;以4KB为单位
                                                  
         prgentry         dd start                ;程序入口#0x10 
         code_seg         dd section.code.start   ;代码段位置#0x14
         code_len         dd code_end             ;代码段长度#0x18

         data_seg         dd section.data.start   ;数据段位置#0x1c
         data_len         dd data_end             ;数据段长度#0x20

         tcb_base         dd 0x00                 ; base_address of current tcb #0x24

;-------------------------------------------------------------------------------
         ;符号地址检索表
         salt_items       dd (header_end-salt)/256 ;#0x28
         
         salt:                                     ;#0x2c
         PrintString      db  '@PrintString'
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram'
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData'
                     times 256-($-ReadDiskData) db 0

         nextTask         db  '@nextTask'
                     times 256 - ($ - nextTask) db 0
                 
header_end:
  
;===============================================================================
SECTION data vstart=0                

         message_1        db  0x0d,0x0a
                          db  '[USER TASK   ]: Hi! nice to meet you,'
                          db  'I am run at CPL=',0
                          
         message_2        db  0
                          db  '.Now,I must exit...',0x0d,0x0a,0

data_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0
start:
         ;任务启动时，DS指向头部段，也不需要设置堆栈 
         mov eax,ds
         mov fs,eax
     
         mov eax,[data_seg]
         mov ds,eax
     
;---------------------------------------ch15 ex02 start----------------------------------

         mov ax, [fs : tcb_base]
         mov bx, 10
         xor dx, dx
         div bx
         or dl, 0x30
         mov [message_1 + 13], dl              ; task num
         
         mov ebx,message_1
         call far [fs:PrintString]
         
         mov ax,cs
         and al,0000_0011B
         or al,0x0030
         mov [message_2],al
         
;---------------------------------------ch15 ex02 end----------------------------------

         mov ebx,message_2
         call far [fs:PrintString]

;---------------------------------------ch15 ex02 start----------------------------------
         
         mov eax, [fs : tcb_base]              ; base_AD of current tcb
         call far [fs : nextTask]              ; into next task by tcb

;---------------------------------------ch15 ex02 end----------------------------------
     
         call far [fs:TerminateProgram]      ;退出，并将控制权返回到核心 
    
code_end:

;-------------------------------------------------------------------------------
SECTION trail
;-------------------------------------------------------------------------------
program_end:
