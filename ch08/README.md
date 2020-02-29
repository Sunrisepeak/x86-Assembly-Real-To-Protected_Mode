### write vhd
>   logic-section: 8
```
    xxd ch08-ex01.asm > temp.txt
    vim temp.txt
        :0,$s/00000/00001/g
        :wq
    cat temp.txt | xxd -r - ../testVM/testVM.vhd

```
