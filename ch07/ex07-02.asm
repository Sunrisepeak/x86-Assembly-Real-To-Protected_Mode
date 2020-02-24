message db '1+2+3+...+1000='
data dw 0x00, 0x00      ;save sum

start:
        mov ax, 0x7c0   ;Data segment Address
        mov ds, ax

        mov ax, 0xb800  ;Video Memory Address
        mov es, ax

        ;print string message
        mov si, message
        mov di, 0
        mov cx, data - message
    l1:
        mov al, [si]
        mov [es:di], al
        inc di
        mov byte [es:di], 0x0E  ; KRGB IRGB
        inc di
        inc si
        loop l1

        ;computaion sum
        mov cx, 1
    l2:
        add [data], cx          ; low-byte of sum
        adc word [data + 2], 0  ; high-byte of sum
        ;jnc @if1               ; method 2
        ;inc word [data + 2]
    @if1:
        inc cx
        cmp cx, 1000 
        jle l2

        ; compuatioin each digits for sum
        xor cx, cx              ; set stack base_address
        mov ss, cx
        mov sp, cx

        mov bx, 10
        xor cx, cx
    l3:                         ; double word div and mod
        inc cx
        mov dx, [data + 2]
        mov ax, [data]
        div bx
        or dl, 0x30 ;to ASCII
        push dx

        mov [data], ax
        mov ax, [data + 2]
        xor dx, dx
        div bx
        mov [data + 2], ax
                                ;while [data] != 0 && [data + 2] != 0
        cmp word [data], 0
        jne l3
        cmp word [data + 2], 0
        jne l3

    @print:
        pop dx
        mov [es:di], dl
        inc di
        mov byte [es:di], 10001100b
        inc di
        loop @print
        
        jmp near $
times 510 - ($ - $$) db 0
                     db 0x55, 0xaa
