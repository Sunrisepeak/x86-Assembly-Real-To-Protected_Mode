         ;代码清单13-3
         ;文件名：c13.asm
         ;文件说明：用户程序 
         ;创建日期：2011-10-30 15:19   
         
         file_address equ 16 

;===============================================================================
SECTION header vstart=0

         program_length   dd program_end          ;程序总长度#0x00
         
         head_len         dd header_end           ;程序头部的长度#0x04

;-----------------------------Ex01 start----------------------------------------
         
         stack_set        dd stack_seg            ; kernel allocate_stack | 0: kernel-allocate other(s-pointer): user-allocate #0x08 
         stack_req_len    dd 1                    ; request len #0x0c
                                                  ; 以4KB为单位
             
;-----------------------------ex01 end------------------------------------------
                                                  
         prgentry         dd start                ;程序入口#0x10 
         code_seg         dd section.code.start   ;代码段位置#0x14
         code_len         dd code_end             ;代码段长度#0x18

         data_seg         dd section.data.start   ;数据段位置#0x1c
         data_len         dd data_end             ;数据段长度#0x20

;----------------------------------ex01 start-----------------------------------

         stack_seg        dd section.stack.start  ; stack-seg local #0x24
         stack_len        dd stack_end            ; stack-len #0x28
             
;----------------------------------ex01 end-------------------------------------
         ;符号地址检索表
         salt_items       dd (header_end-salt)/256 ;#0x2c
         
         salt:                                     ;#0x30
         PrintString      db  '@PrintString'
                     times 256-($-PrintString) db 0
                     
         TerminateProgram db  '@TerminateProgram'
                     times 256-($-TerminateProgram) db 0
                     
         ReadDiskData     db  '@ReadDiskData'
                     times 256-($-ReadDiskData) db 0
                 
header_end:

;----------------------------------ex01 start-----------------------------------

 SECTION stack align=16 vstart=0

         resb 512                                 ; 512 byte

stack_end:

;----------------------------------ex01 end-------------------------------------


;===============================================================================
SECTION data vstart=0    
                         
         buffer times 1024 db  0         ;缓冲区

         message_1         db  0x0d,0x0a,0x0d,0x0a
                           db  '**********User program is runing**********'
                           db  0x0d,0x0a,0
         message_2         db  '  Disk data:',0x0d,0x0a,0

data_end:

;===============================================================================
      [bits 32]
;===============================================================================
SECTION code vstart=0
start:
         mov eax,ds
         mov fs,eax
     
         mov eax,[stack_seg]
         mov ss,eax
         mov esp,0
     
         mov eax,[data_seg]
         mov ds,eax
     
         mov ebx,message_1
         call far [fs:PrintString]
     
         ;mov eax,file_address                ;file逻辑扇区号
         ;mov ebx,buffer                      ;缓冲区偏移地址

;----------------------------ch14 ex02 start----------------------------------
         
         push dword file_address             ; set sector 
         push dword ds                       ; set select of target area
         push dword buffer                   ; set offset

         call far [fs:ReadDiskData]          ;段间调用

;----------------------------ch14 ex02 end------------------------------------
     
         mov ebx,message_2
         call far [fs:PrintString]
     
         mov ebx,buffer 
         call far [fs:PrintString]           ;too.
     
         ;jmp far [fs:TerminateProgram]       ;将控制权返回到系统 
      
;----------------------------ch14 ex01 start----------------------------------

         call far [fs:TerminateProgram]       ;using call far return to sys by gate

;----------------------------ch14 ex01 end------------------------------------

code_end:

;===============================================================================
SECTION trail
;-------------------------------------------------------------------------------
program_end:
