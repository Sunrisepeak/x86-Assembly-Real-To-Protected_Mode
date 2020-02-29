         ;代码清单8-2
         ;文件名：c08.asm
         ;文件说明：用户程序 
         ;创建日期：2011-5-5 18:17
         
;===============================================================================
SECTION header vstart=0                     ;定义用户程序头部段 
    program_length  dd program_end          ;程序总长度[0x00]
    
    ;用户程序入口点
    code_entry      dw start                ;偏移地址[0x04]
                    dd section.code_1.start ;段地址[0x06] 
    
    realloc_tbl_len dw (header_end-code_1_segment)/4
                                            ;段重定位表项个数[0x0a]
    
    ;段重定位表           
    code_1_segment  dd section.code_1.start ;[0x0c]
    code_2_segment  dd section.code_2.start ;[0x10]
    data_1_segment  dd section.data_1.start ;[0x14]
    data_2_segment  dd section.data_2.start ;[0x18]
    data_3_segment  dd section.data_3.start ;[0x1c]         ; add a data_seg to test screen_roll
    stack_segment   dd section.stack.start  ;[0x20]
    
    header_end:                
    
;===============================================================================
SECTION code_1 align=16 vstart=0         ;定义代码段1（16字节对齐） 
put_string:                              ;显示串(0结尾)。
                                         ;输入：DS:BX=串地址
                                         ;put_string(address DS:BX, color al)
         mov cl,[bx]
         or cl,cl                        ;cl=0 ?
         jz .exit                        ;是的，返回主程序 
         call put_char
         call delay_func                 ; add a litte delay when print a char
         inc bx                          ;下一个字符 
         jmp put_string

   .exit:
         ret

;-------------------------------------------------------------------------------
put_char:                                ;显示一个字符
                                         ;输入：cl=字符ascii
                                         ;put_char(char cl, color al)
         push ax
         push bx
         push cx
         push dx
         push ds
         push es
         push si

         mov si, ax                         ;save color attribute to si

         ;以下取当前光标位置
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;高8位 
         mov ah,al

         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         in al,dx                        ;低8位 
         mov bx,ax                       ;BX=代表光标位置的16位数

         cmp cl,0x0d                     ;回车符？
         jnz .put_0a                     ;不是。看看是不是换行等字符 
         mov ax,bx                       ;此句略显多余，但去掉后还得改书，麻烦 
         mov bl,80                       
         div bl
         mul bl
         mov bx,ax
         jmp .set_cursor

 .put_0a:
         cmp cl,0x0a                     ;换行符？
         jnz .put_other                  ;不是，那就正常显示字符 
         add bx,80
         jmp .roll_screen

 .put_other:                             ;正常显示字符
         mov ax,0xb800
         mov es,ax
         shl bx,1
         mov [es:bx],cl

         mov ax, si                      ; color_attribute to ax
         mov [es:bx + 1],al              ; set color_attribute of char

         ;以下将光标位置推进一个字符
         shr bx,1
         add bx,1

 .roll_screen:
         cmp bx,2000                     ;光标超出屏幕？滚屏
         jl .set_cursor

         mov ax,0xb800
         mov ds,ax
         mov es,ax
         cld
         mov si,0xa0
         mov di,0x00
         mov cx,1920
         rep movsw
         mov bx,3840                     ;清除屏幕最底一行
         mov cx,80
 .cls:
         mov word[es:bx],0x0720
         add bx,2
         loop .cls

         mov bx,1920

 .set_cursor:
         mov dx,0x3d4
         mov al,0x0e
         out dx,al
         mov dx,0x3d5
         mov al,bh
         out dx,al
         mov dx,0x3d4
         mov al,0x0f
         out dx,al
         mov dx,0x3d5
         mov al,bl
         out dx,al

         pop si
         pop es
         pop ds
         pop dx
         pop cx
         pop bx
         pop ax

         ret

;-------------------------------------------------------------------------------
  start:
         ;初始执行时，DS和ES指向用户程序头部段
         mov ax,[stack_segment]           ;设置到用户程序自己的堆栈 
         mov ss,ax
         mov sp,stack_end
         
         mov ax,[data_1_segment]          ;设置到用户程序自己的数据段
         mov ds,ax

         mov bx,msg0
         mov al, 00000101b
         call put_string                  ;显示第一段信息 

         ;push word [es:code_2_segment]
         ;mov ax,begin
         ;push ax                         ;可以直接push begin,80386+
         
         ;retf                            ;转移到代码段2执行 
;******************************Ex08-1*****************************************
         
         mov ax, [es:code_2_segment]        ; modify segment_redirect_table
         mov [es:code_2_segment + 2], ax    
         mov word [es:code_2_segment], begin 
         mov ax, es
         mov ds, ax                         ; modify data_seg reg


         jmp far [code_2_segment]           ; Note: jmp far using data_seg make seg_address
  
  print_info:
         mov cx, 4 
  @test:
         mov ax, [es:data_3_segment]
         mov ds, ax
         
         mov bx, msg2                     ; address
         mov al, 00000010b                ; set background_color: black, char: aqua
        
         push cx
         call put_string                  ; put_string cann't call in code_2_seg
         pop cx

         loop @test

         jmp near continue

delay_func:
         push cx

         mov cx, 400 
  @delay:                                 ; delay1
         push cx
         mov cx, 40000
         loop $                           ; delay2
         pop cx
         loop @delay
         
         pop cx
         ret
;*****************************************************************************

  continue:
         mov ax,[es:data_2_segment]       ;段寄存器DS切换到数据段2 
         mov ds,ax
         
         mov bx,msg1
         mov al, 0x07
         call put_string                  ;显示第二段信息 

         jmp $ 

;===============================================================================
SECTION code_2 align=16 vstart=0          ;定义代码段2（16字节对齐）
;
;  begin:
;         mov cx, 10
;
;  test:                                   ; Test screen_roll
;         mov ax, [es:data_3_segment]
;         mov ds, ax
;         
;         mov bx, msg2                     ; address
;         mov al, 01110100b                ; set background_color: white, char: red
;         
;         call put_string                 ; put_string cann't call in code_2_seg
;                                          ; spend 1h  ---debug
;
;         loop test

  begin:
         push word [es:code_1_segment]
         mov ax,print_info
         push ax                          ;可以直接push continue,80386+
         
         retf                             ;转移到代码段1接着执行 
         
;===============================================================================
SECTION data_1 align=16 vstart=0

    msg0 db '  This is NASM - the famous Netwide Assembler. '
         db 'Back at SourceForge and in intensive development! '
         db 'Get the current versions from http://www.nasm.us/.'
         db 0x0d,0x0a,0x0d,0x0a
         db '  Example code for calculate 1+2+...+1000:',0x0d,0x0a,0x0d,0x0a
         db '     xor dx,dx',0x0d,0x0a
         db '     xor ax,ax',0x0d,0x0a
         db '     xor cx,cx',0x0d,0x0a
         db '  @@:',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     add ax,cx',0x0d,0x0a
         db '     adc dx,0',0x0d,0x0a
         db '     inc cx',0x0d,0x0a
         db '     cmp cx,1000',0x0d,0x0a
         db '     jle @@',0x0d,0x0a
         db '     ... ...(Some other codes)',0x0d,0x0a,0x0d,0x0a
         db 0

;===============================================================================
SECTION data_2 align=16 vstart=0

    msg1 db '  The above contents is written by LeeChung. '
         db '    2011-05-06', 0x0d, 0x0a
         db '  The above contents is modified by SPeakShen. '
         db '    2020-02-29, 10:37PM'
         db 0

;*************************Test-DataSegment**************************************
SECTION data_3 align=16 vstart=0

    msg2 db '  This is a test for roll_screen.               ', 0x0d, 0x0a
         db '                                   by SPeakShen', 0x0d, 0x0a
         db '                                    2020-02-29 ', 0x0d, 0x0a
         db 0

;*******************************************************************************
SECTION stack align=16 vstart=0
           
         resb 256

stack_end:  

;===============================================================================
SECTION trail align=16
program_end:
