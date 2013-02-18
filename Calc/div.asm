               org     100h

                mov     di, arg1
                mov     cx, numsize
                call    read_long

                mov     di, arg2
                mov     cx, numsize
                call    read_long

                mov     si, arg1
                mov     cx, numsize
                call    div_2long

                call    print_long

                mov     ax, 4c00h
                int     21h

; es:di - long number
; cx    - length in words
fill_zeros:
                push    cx
                push    di
                xor         ax, ax
                rep         stosw
                pop         di
                pop         cx
                ret

; es:di - long number
; dx - number of zeros
; in result di - followed by last zero byte
add_zeros:
        push    dx        
@@:
        test    dx, dx
        jz      @f        
        xor     ax, ax
        mov     [di], ax
        add     di, 2
        dec     dx
        jmp     @b
@@:
        pop     dx
        ret

;es:di - long number 1
;ds:si - long number 2
;cx - length in words
copy_long:
        push    di
        push    si
        push    ax
        push    cx

@@:     
        test    cx, cx
        jz      @f  
        mov     ax, [di]
        mov     [si], ax
        add     di, 2
        add     si, 2
        dec     cx
        jmp     @b
@@:           
        pop     cx
        pop     ax
        pop     si
        pop     di
        
        ret

;es:di - long number 1
;ds:si - long number 2
;in result sets flags analogue cmp
cmp_long:
        push    di
        push    si
        push    cx
        add     di, cx
        add     si, cx
        add     di, 2
        add     si, 2
@@:
        test    cx, cx
        jz      @f
        dec     cx
        sub     di, 2
        sub     si, 2
        mov     ax, [di]
        cmp     ax, [si]
        je      @b
@@:
        pop     cx
        pop     si
        pop     di
        
        ret

; es:di - long number
; cx    - length in words
; bx    - summand
add_long:
                push    ax
                push    cx
                push    dx
                push    di

@@:
                or      cx, cx
                jz      @f

                xor     dx, dx
                add     [di], bx
                adc     dx, 0
                mov     bx, dx
                add     di, 2
                dec     cx
                jmp     @b

@@:
                pop     di
                pop     dx
                pop     cx
                pop     ax
                ret
                
; es:di - long number
; cx    - length in words
; dx    - loan (0 or 1)
sub_loan:
                push    ax
                push    di
                mov     ax, [di]

@@:
                test    ax, ax
                jnz         @f
                add     ax, 9
                mov     [di], ax 
                add         di, 2
                mov     ax, [di]
                jmp         @b
@@:
        sub ax, dx
        mov [di], ax
                pop     di
                pop     ax
                ret
; es:di - long number
; cx    - length in words
; dx    - loan (0 or 1)
add_loan:
                push    bx
                push    di
                mov     bx,1
@@:
                test    bx, bx
                jz          @f
        
        xor     bx, bx
                add         [di], dx
                adc         bx, 0
                add         di, 2
                jmp         @b

@@:
                pop         di
                pop     bx
                ret

; es:di - long number 1
; ds:si - long number 2
; result is stored in es:di
mul_2long:
                push    ax
                push    bx
                push    cx
                push    dx
                push    di
                push    si
                
                mov     bx, [si]
                mov     dx, 0
                
                push    si
                mov     si, res
                call    copy_long
                pop     si
                
                push    di
                mov     di, res
                call    mul_long
                pop     di
                
                push    si
                mov     si, mul_tmp
                call    copy_long
                pop     si

@@:
                or      cx, cx
                jz      @f
                
                inc     dx
                dec     cx
                
                push    si
                push    di
                mov     di, mul_tmp
                call    add_zeros
                mov     si, di                
                pop     di
                call    copy_long
                pop     si                

                add     si, 2
                mov     bx, [si]
                  
                push    di
                mov     di, mul_tmp
                call    mul_long
                pop     di
                
                push    di
                push    si
                mov     di, res
                mov     si, mul_tmp
                call    add_2long
                pop     si
                pop     di                

                jmp     @b                                                 

@@:     
                push    di
                push    si
                mov     si, di
                mov     di, res
                call    copy_long
                pop     si
                pop     di                          
                
                pop si
                pop di
                pop dx
                pop cx
                pop bx
                pop ax
                push    si
                push    di
                mov     si, di
                mov     di, res
                call    copy_long
                pop     di
                pop     si
                ret

; es:di - long number 1
; ds:si - long number 2
; cx    - length in words
; result is stored in es:di
add_2long:
        push    bx
                push    cx
                push    di

                xor     ax, ax
@@:
                or      cx, cx        ;cx=0?
                jz      @f

                xor     bx, bx
                add     ax, [di]
                adc     bx, 0         ;add with CF and put flags z=1, p=1
                add     ax, [si]
                adc     bx, 0
                mov     [di], ax
                mov     ax, bx

                add     di, 2
                add     si, 2
                dec     cx
                jmp     @b

@@:
                pop     di
                pop     cx
                pop bx
                ret
                
; ds:di - long number 1
; ds:si - long number 2
; cx    - length in words
; result is stored in ds:di
sub_2long:
        push    ax
        push    bx
        push    dx
        push    cx
        push    di
        push    si

                
        xor bx, bx        ;counter of loan

@@:
                or      cx, cx        ;cx=0?
                jz      @f
                xor     ax, ax
                add     ax, [di]
                cmp     ax, [si]
                jae     .simple_sub      
                mov     dx, 65535       
                sub     dx, [si]
                add     ax, dx
                inc     ax         
                mov     [di], ax
                add     di, 2
                add     si, 2
                mov     ax, [di]
                push    di
                test    ax, ax
                jnz     .continue
.get_loan:
                mov     ax, 65535
                mov     [di], ax
                add     di, 2
                mov     ax, [di]
                test    ax, ax
                jz      .get_loan
.continue:
                mov     ax, 1
                sub     [di], ax
                pop     di                
                        dec         cx
                        jmp     @b
.simple_sub:
                sub     ax, [si]
                mov     [di], ax
                add     di, 2
                add     si, 2
                dec     cx
                jmp     @b

@@:
        pop si
        pop     di
        pop     cx
        pop dx
        pop bx
        pop ax
        ret


; es:di - long number 1
; ds:si - long number 2
; result is stored in es:di
div_2long:
        xchg    di, si
        push    ax
        push    bx
        push    cx
        mov     bx, 2
        
        push    di
        mov     di, div_res
        call    fill_zeros
        pop     di       
        
        push    si
        mov     si, div_res
        call    copy_long
        pop     si
        
        push    di
        xor     di, di
        mov     di, div_res
        call    div_long
        pop     di               
        
        push    di
        push    si
        mov     di, div_res
        mov     si, sub_tmp
        call    copy_long
        pop     si
        pop     di 
continue:
        push    di
        mov     di, div_tmp
        call    fill_zeros
        pop     di
        
        push    di
        push    si
        mov     di, div_res
        mov     si, div_tmp
        call    copy_long
        pop     si
        mov     di, div_tmp
        call    mul_2long
        pop     di
                
        push    si
        mov     si, div_tmp
        call    cmp_long
        jb      is_below
        ja      is_above 
        je      is_equal
pop_back:
        pop     si
        pop     di     
get_res:        
        push    di
        mov     si, di
        mov     di, div_res
        call    copy_long 
        pop     di     
        pop     si
        
        pop     cx
        pop     bx
        pop     ax
        
        ret
is_below:
        push    di
        mov     di, sub_tmp
        call    div_long
        mov     di, div_res
        mov     si, sub_tmp
        call    sub_loan
        call    sub_2long
        pop     di 
        pop     si  
        jmp     continue 
          
is_above:
        push    di
        push    si
        mov     si, tmp
        call    copy_long
        mov     di, tmp
        mov     si, div_tmp
        call    sub_2long 
        mov     si, arg2
        call    cmp_long
        jb      pop_back
        pop     si
        pop     di
                ;???
        push    di
        push    si
        mov     di, sub_tmp
        call    div_long
        mov     di, div_res
        mov     si, sub_tmp
        call    add_loan
        call    add_2long
        pop     si
        pop     di
        pop     si
        jmp     continue                        
        
is_equal:
        call    fill_zeros
        push    di
        push    si
        xchg    di, si 
        call    copy_long
        pop     si
        pop     di
        jmp     get_res

; es:di - long number
; cx    - length in words
; bx    - multiplier
mul_long:
                push    ax
                push    bx
                push    cx
                push    dx
                push    di
        push    si

                xor     si, si

@@:
                or      cx, cx
                jz      @f

                mov     ax, [di]
                mul     bx
                add     ax, si
                adc     dx, 0
                mov     [di], ax
                add     di, 2
                mov     si, dx

                dec     cx
                jmp     @b

@@:
        pop si
                pop     di
                pop     dx
                pop     cx
                pop     bx
                pop     ax
                ret



; es:di - long number
; cx    - length in words
; bx    - divisor
; returns remainder in dx
div_long:
                push    cx
                push    di

                add     di, cx
                add     di, cx
                xor     dx, dx

@@:
                or      cx, cx
                jz      @f

                sub     di, 2
                mov     ax, [di]
                div     bx
                mov     [di], ax

                dec     cx
                jmp     @b
@@:
                pop     di
                pop     cx
                ret

; es:di - long number
; cx    - length in words
; returns result in cf
is_zero:
                push    cx
                push    di
@@:
                or      cx, cx
                jz      @f
                mov     ax, [di]
                add     di, 2
                dec     cx
                or      ax, ax
                jz      @b
                clc
                jmp     is_zero_quit
@@:
                stc
is_zero_quit:
                pop     di
                pop     cx
                ret

; es:di - long number
; cx    - length in words
print_long:
                mov     si, print_long_buf + print_long_buf_size
                dec     si
                mov     byte [si], '$'
                dec     si
                mov     byte [si], 10
                dec     si
                mov     byte [si], 13
                mov     bx, 10

@@:
                call    div_long
                add     dl, '0'
                dec     si
                mov     [si], dl

                call    is_zero
                jnz     @b

                mov     ah, 9
                mov     dx, si
                int     21h

                ret

; es:di - long number
; cx    - length in words
read_long:
                push    es
                mov     ax, ds
                mov     es, ax
                call    fill_zeros
                pop     es

read_long_read_again:
                mov     ah, 8
                int     21h

                cmp     al, 13
                jz      read_long_quit

                cmp     al, '0'
                jb      read_long_read_again

                cmp     al, '9'
                ja      read_long_read_again

                mov     dl, al
                push    dx
                mov     ah, 2
                int     21h
                pop     dx

                mov     bx, 10
                call    mul_long

                sub     dl, '0'

                xor     bx, bx
                mov     bl, dl
                call    add_long

                jmp     read_long_read_again

read_long_quit:
                mov     ah, 9
                mov     dx, crlf
                int     21h

                ret

crlf:           db      13,10,'$'

numsize = 1024
arg1:           rw      numsize
arg2:           rw      numsize
mul_tmp:    rw  numsize
div_tmp:    rw  numsize
sub_tmp:    rw  numsize
tmp:        rw  numsize
res:        rw  numsize
div_res:    rw  numsize
print_long_buf_size = 8192

print_long_buf: rb      print_long_buf_size