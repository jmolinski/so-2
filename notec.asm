; autor Jakub Molinski 419502

; TODO tryby

        global notec

        section .text

; uint64_t notec(uint32_t n, char const *calc);
notec:
        push r13                       ; Dla zgodności z ABI zapisujemy rejestry r13-r15.
        push r14
        push r15
        mov r14, rdi                   ; r14 - N
        mov r15, rsi                   ; r15 - adres ciągu instrukcji

; TODO push na stos zeby nie bylo sigsegv
        xor rax, rax
        push rax

.loop_over_instructions:
        xor eax, eax                   ; czy potrzebne? TODO
        mov al, [r15]                  ; Wczytujemy następną instrukcje.
        mov dl, al                     ; Kopia wczytanej instrukcji.
        inc r15                        ; Przesuwamy wskaźnik na następną instrukcję.
        test al, al                    ; Sprawdzamy czy to koniec ciągu instrukcji.
        jz .exit

        cmp al, '&'
        je .and_operation
        cmp al, '*'
        je .product_operation
        cmp al, '+'
        je .sum_operation
        cmp al, '-'
        je .negate_operation
        mov edx, eax
        sub dl, '9'
        cmp al, '9'
        cmovbe eax, edx
        jbe .letter_handler
        cmp al, '='
        je .exit_insert_mode
        mov edx, eax
        sub dl, 'F'                    ; Przesunięcie aby litery A..F miały wartości 10..15.
        add dl, 10
        cmp al, 'F'
        cmovbe eax, edx
        jbe .letter_handler
        cmp al, 'N'
        je .push_number_of_machines
        cmp al, 'W'
        je .exchange_with_other_machine
        cmp al, 'X'
        je .exchange_stack_top
        cmp al, 'Y'
        je .duplicate_stack_top
        cmp al, 'Z'
        je .remove_stack_top
        cmp al, '^'
        je .xor_operation
        mov edx, eax
        sub dl, 'f'                    ; Przesunięcie aby litery a..f miały wartości 10..15.
        add dl, 10
        cmp al, 'f'
        cmovbe eax, edx
        jbe .letter_handler
        cmp al, 'g'
        je .call_debug
        cmp al, 'n'
        je .push_machine_number_on_stack
        cmp al, '|'
        je .or_operation
        jmp .bitwise_not_operation

; & – Zdejmij dwie wartości ze stosu, wykonaj na nich operację AND i wstaw wynik na stos.
.and_operation:
        jmp .loop_over_instructions
; * – Zdejmij dwie wartości ze stosu, oblicz ich iloczyn i wstaw wynik na stos.
.product_operation:
        jmp .loop_over_instructions
; + – Zdejmij dwie wartości ze stosu, oblicz ich sumę i wstaw wynik na stos.
.sum_operation:
        jmp .loop_over_instructions
; - – Zaneguj arytmetycznie wartość na wierzchołku stosu.
.negate_operation:
        jmp .loop_over_instructions
; = – Wyjdź z trybu wpisywania liczby.
.exit_insert_mode:
        jmp .loop_over_instructions
; N – Wstaw na stos liczbę Noteci.
.push_number_of_machines:
        jmp .loop_over_instructions
; W – Zdejmij wartość ze stosu, potraktuj ją jako numer instancji Notecia m.
; Czekaj na operację W Notecia m ze zdjętym ze stosu numerem instancji Notecia n i zamień wartości na wierzchołkach stosów Noteci m i n.
.exchange_with_other_machine:
        jmp .loop_over_instructions
; X – Zamień miejscami dwie wartości na wierzchu stosu.
.exchange_stack_top:
        jmp .loop_over_instructions
; Y – Wstaw na stos wartość z wierzchołka stosu, czyli zduplikuj wartość na wierzchu stosu.
.duplicate_stack_top:
        jmp .loop_over_instructions
; Z – Usuń wartość z wierzchołka stosu.
.remove_stack_top:
        jmp .loop_over_instructions
; ^ – Zdejmij dwie wartości ze stosu, wykonaj na nich operację XOR i wstaw wynik na stos.
.xor_operation:
        jmp .loop_over_instructions
;g – Wywołaj (zaimplementowaną gdzieś indziej w języku C lub Asemblerze) funkcję:
.call_debug:
        jmp .loop_over_instructions
; n – Wstaw na stos numer instancji tego Notecia.
.push_machine_number_on_stack:
        jmp .loop_over_instructions
; | – Zdejmij dwie wartości ze stosu, wykonaj na nich operację OR i wstaw wynik na stos.
.or_operation:
        jmp .loop_over_instructions
; ~ – Zaneguj bitowo wartość na wierzchołku stosu.
.bitwise_not_operation:
        jmp .loop_over_instructions

; 48-57 litera
; 65-70 litera
; 97-102 litera
.letter_handler:
        jmp .loop_over_instructions

.exit:
; TODO pop wszystko co zostało?
        pop rax                        ; zdejmujemy ostatni element który został na stosie
        pop r15                        ; Dla zgodności z ABI przywracamy rejestry r13-r15.
        pop r14
        pop r13
        ret
