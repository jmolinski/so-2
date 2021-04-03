; autor Jakub Molinski 419502

        PUSH_MODE equ 0
        NUMBER_INSERT_MODE equ 1
        MAX_HEX_DIGIT_VALUE equ 15

        global notec
        extern debug

        section .text

; uint64_t notec(uint32_t n, char const *calc);
notec:
        push r13                       ; Dla zgodności z ABI zapisujemy rejestry r13-r15.
        push r14
        push r15
        mov r14d, edi                  ; r14 - n
        mov r15, rsi                   ; r15 - adres ciągu instrukcji

.loop_condition:
        mov r13d, PUSH_MODE

.loop_condition_without_setting_push_mode:

        xor rax, rax                   ; TODO eax
        mov al, [r15]                  ; Wczytujemy następną instrukcje.
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
        sub dl, '0'
        cmp dl, 9
        cmovbe eax, edx
        jbe .letter_handler
        cmp al, '='                    ; = – Wyjdź z trybu wpisywania liczby.
        je .loop_condition
        mov edx, eax
        sub dl, 'A'                    ; Przesunięcie aby litery A..F miały wartości 10..15.
        add dl, 10
        cmp dl, MAX_HEX_DIGIT_VALUE
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
        sub dl, 'a'                    ; Przesunięcie aby litery a..f miały wartości 10..15.
        add dl, 10
        cmp dl, MAX_HEX_DIGIT_VALUE
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
        pop rax
        pop rdx
        and rax, rdx
        push rax
        jmp .loop_over_instructions
; * – Zdejmij dwie wartości ze stosu, oblicz ich iloczyn i wstaw wynik na stos.
.product_operation:
        pop rax
        pop rdx
        mul rdx
        push rax
        jmp .loop_over_instructions
; + – Zdejmij dwie wartości ze stosu, oblicz ich sumę i wstaw wynik na stos.
.sum_operation:
        pop rax
        pop rdx
        add rax, rdx
        push rax
        jmp .loop_over_instructions
; - – Zaneguj arytmetycznie wartość na wierzchołku stosu.
.negate_operation:
        pop rax
        neg rax
        push rax
        jmp .loop_over_instructions
; Y – Wstaw na stos wartość z wierzchołka stosu, czyli zduplikuj wartość na wierzchu stosu.
.duplicate_stack_top:
        pop rax
        push rax
        push rax
        jmp .loop_over_instructions
; n – Wstaw na stos numer instancji tego Notecia.
.push_machine_number_on_stack:
        push r14
        jmp .loop_over_instructions
; Z – Usuń wartość z wierzchołka stosu.
.remove_stack_top:
        pop rax
        jmp .loop_over_instructions
; N – Wstaw na stos liczbę Noteci.
.push_number_of_machines:
        mov eax, N
        push rax
        jmp .loop_over_instructions
; X – Zamień miejscami dwie wartości na wierzchu stosu.
.exchange_stack_top:
        pop rax
        pop rdx
        push rax
        push rdx
        jmp .loop_over_instructions
; ^ – Zdejmij dwie wartości ze stosu, wykonaj na nich operację XOR i wstaw wynik na stos.
.xor_operation:
        pop rax
        pop rdx
        xor rax, rdx
        push rax
        jmp .loop_over_instructions
; | – Zdejmij dwie wartości ze stosu, wykonaj na nich operację OR i wstaw wynik na stos.
.or_operation:
        pop rax
        pop rdx
        or rax, rdx
        push rax
        jmp .loop_over_instructions
; ~ – Zaneguj bitowo wartość na wierzchołku stosu.
.bitwise_not_operation:
        pop rax
        not rax
        push rax
        jmp .loop_over_instructions

.loop_over_instructions:
        jmp .loop_condition

; W – Zdejmij wartość ze stosu, potraktuj ją jako numer instancji Notecia m.
; Czekaj na operację W Notecia m ze zdjętym ze stosu numerem instancji Notecia n i zamień wartości na wierzchołkach stosów Noteci m i n.
.exchange_with_other_machine:
        jmp .loop_over_instructions
;g – Wywołaj (zaimplementowaną gdzieś indziej w języku C lub Asemblerze) funkcję:
.call_debug:
; int64_t debug(uint32_t n, uint64_t *stack_pointer);
; Parametr n zawiera numer instancji Notecia wywołującego tę funkcję.
; Parametr stack_pointer wskazuje na wierzchołek stosu Notecia.
; Funkcja debug może zmodyfikować stos. Wartość zwrócona przez tę funkcję oznacza,
; o ile pozycji należy przesunąć wierzchołek stosu po jej wykonaniu.
        mov edi, r14d
        mov rsi, rsp
        call debug
        mov edi, 8
        mul rdi                        ; TODO znaki?
        add rsp, rax
        jmp .loop_over_instructions

; 0 to 9, A to F, a to f – Znak jest interpretowany jako cyfra w zapisie przy podstawie 16.
; Jeśli Noteć jest w trybie wpisywania liczby, to liczba na wierzchołku stosu jest przesuwana o jedną pozycję
; w lewo i uzupełniania na najmniej znaczącej pozycji podaną cyfrą. Jeśli Noteć nie jest w trybie wpisywania liczby,
; to na wierzchołek stosu jest wstawiana wartość podanej cyfry. Noteć przechodzi w tryb wpisywania liczby
; po wczytaniu jednego ze znaków z tej grupy, a wychodzi z trybu wpisywania liczby po wczytaniu dowolnego znaku
; nie należącego to tej grupy.
.letter_handler:
        cmp r13d, NUMBER_INSERT_MODE
        je .letter_handler_shift_mode
        mov r13d, NUMBER_INSERT_MODE
        push rax
        jmp .exit_letter_handler
.letter_handler_shift_mode:
        pop rdi
        shl rdi, 4
        or rdi, rax
        push rdi
.exit_letter_handler:
        jmp .loop_condition_without_setting_push_mode

.exit:
        pop rax                        ; zdejmujemy ostatni element który został na stosie
        pop r15                        ; Dla zgodności z ABI przywracamy rejestry r13-r15.
        pop r14
        pop r13
        ret
