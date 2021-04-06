; autor Jakub Molinski 419502

        PUSH_MODE equ 0
        NUMBER_INSERT_MODE equ 1

        NOT_INITIALIZED equ 0
        IS_READ equ 1
        IS_UNREAD equ 2

        INVALID_NOTEC_ID equ -1
        LOWERCASE_UPPERCASE_DIFF equ 32
        UPPERCASE_HEX_TO_INT_DIFF equ 55
        BITS_PER_HEX_DIGIT equ 4

        global notec
        extern debug

        section .bss
        align 8
        stack_top_value resq N
        waiting_for resd N
        notec_exchange_state resb N

        section .text

notec:
        push rbp
        push r12                       ; Dla zgodności z ABI zapisujemy rejestry r12-r15.
        push r13
        push r14
        push r15
        mov rbp, rsp                   ; Zapisuję adres powrotu.
        mov r14d, edi                  ; r14 - n (numer notecia).
        mov r15, rsi                   ; r15 - adres ciągu instrukcji.

        lea rdx, [rel waiting_for]     ; Inicjalizacja zmiennych służących synchronizacji.
        mov dword [rdx + rdi*4], INVALID_NOTEC_ID
        lea rdx, [rel notec_exchange_state]
        mov byte [rdx + r14], IS_READ

.loop_condition:
        mov r13d, PUSH_MODE

.loop_condition_without_setting_push_mode:
        xor eax, eax
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
        cmp al, '9'
        jbe .digit_handler_under10
        cmp al, '='
        je .loop_condition
        cmp al, 'F'
        jbe .digit_handler_uppercase_letter
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
        cmp al, 'f'
        jbe .digit_handler_lowercase_letter
        cmp al, 'g'
        je .call_debug
        cmp al, 'n'
        je .push_machine_number_on_stack
        cmp al, '|'
        je .or_operation
        jmp .bitwise_not_operation

; Zdejmij dwie wartości ze stosu, wykonaj na nich operację AND i wstaw wynik na stos.
.and_operation:
        pop rax
        pop rdx
        and rax, rdx
        jmp .push_rax_and_loop_over_instructions
; Zdejmij dwie wartości ze stosu, oblicz ich iloczyn i wstaw wynik na stos.
.product_operation:
        pop rax
        pop rdx
        mul rdx
        jmp .push_rax_and_loop_over_instructions
; Zdejmij dwie wartości ze stosu, oblicz ich sumę i wstaw wynik na stos.
.sum_operation:
        pop rax
        pop rdx
        add rax, rdx
        jmp .push_rax_and_loop_over_instructions
; Zaneguj arytmetycznie wartość na wierzchołku stosu.
.negate_operation:
        pop rax
        neg rax
        jmp .push_rax_and_loop_over_instructions
; Wstaw na stos wartość z wierzchołka stosu, czyli zduplikuj wartość na wierzchu stosu.
.duplicate_stack_top:
        pop rax
        push rax
        jmp .push_rax_and_loop_over_instructions
; Wstaw na stos numer instancji tego Notecia.
.push_machine_number_on_stack:
        push r14
        jmp .loop_over_instructions
; Usuń wartość z wierzchołka stosu.
.remove_stack_top:
        pop rax
        jmp .loop_over_instructions
; Wstaw na stos liczbę Noteci.
.push_number_of_machines:
        mov eax, N
        jmp .push_rax_and_loop_over_instructions
; Zamień miejscami dwie wartości na wierzchu stosu.
.exchange_stack_top:
        pop rdx
        pop rax
        push rdx
        jmp .push_rax_and_loop_over_instructions
; Zdejmij dwie wartości ze stosu, wykonaj na nich operację XOR i wstaw wynik na stos.
.xor_operation:
        pop rax
        pop rdx
        xor rax, rdx
        jmp .push_rax_and_loop_over_instructions
; Zdejmij dwie wartości ze stosu, wykonaj na nich operację OR i wstaw wynik na stos.
.or_operation:
        pop rax
        pop rdx
        or rax, rdx
        jmp .push_rax_and_loop_over_instructions
; Zaneguj bitowo wartość na wierzchołku stosu.
.bitwise_not_operation:
        pop rax
        not rax

.push_rax_and_loop_over_instructions:
        push rax
.loop_over_instructions:
        jmp .loop_condition

; 0 to 9, A to F, a to f – Znak jest interpretowany jako cyfra w zapisie przy podstawie 16.
; Jeśli Noteć jest w trybie wpisywania liczby, to liczba na wierzchołku stosu jest przesuwana o jedną pozycję
; w lewo i uzupełniania na najmniej znaczącej pozycji podaną cyfrą. Jeśli Noteć nie jest w trybie wpisywania liczby,
; to na wierzchołek stosu jest wstawiana wartość podanej cyfry. Noteć przechodzi w tryb wpisywania liczby
; po wczytaniu jednego ze znaków z tej grupy, a wychodzi z trybu wpisywania liczby po wczytaniu dowolnego znaku
; nie należącego to tej grupy.
.digit_handler_under10:
        sub al, '0'                    ; Konwersja z ascii cyfry na wartość liczbową.
        jmp .digit_handler
.digit_handler_lowercase_letter:
        sub al, LOWERCASE_UPPERCASE_DIFF ; Zmiana z małej litery na wielką literę.
.digit_handler_uppercase_letter:
        sub al, UPPERCASE_HEX_TO_INT_DIFF ; Zmiana z cyfry A..F na wartość liczbową 10..15.
.digit_handler:
        cmp r13d, NUMBER_INSERT_MODE
        je .digit_handler_shift_mode
        mov r13d, NUMBER_INSERT_MODE
        push rax
        jmp .exit_digit_handler
.digit_handler_shift_mode:
        pop rdi
        shl rdi, BITS_PER_HEX_DIGIT
        or rdi, rax
        push rdi
.exit_digit_handler:
        jmp .loop_condition_without_setting_push_mode

; Wywołuje funkcję debug.
.call_debug:
        mov edi, r14d                  ; Argument - numer Notecia.
        mov rsi, rsp                   ; Argument - wskaźnik na wierzchołek stosu.

        mov r12, rsp                   ; Wyrównanie stosu (wymóg ABI).
        and rsp, -16                   ; Zmiana na najmniejszą liczbę podzielną przez 16 niemniejszą od rsp.
        call debug                     ; Umieszcza w rax o ile pozycji przesunąć stos.

        lea rsp, [r12 + 8*rax]
        jmp .loop_over_instructions

; Zdejmij wartość ze stosu, potraktuj ją jako numer instancji Notecia m.
; Czekaj na operację W Notecia m ze zdjętym ze stosu numerem instancji Notecia n i zamień wartości na wierzchołkach stosów Noteci m i n.
.exchange_with_other_machine:
        pop rdi                        ; Numer notecia m.

        lea rdx, [rel notec_exchange_state]
.busy_wait_for_other_notec_to_be_initialized:
        mov al, [rdx + rdi]            ; Poczekaj aż Noteć m zostanie zainicjalizowany.
        cmp al, NOT_INITIALIZED
        je .busy_wait_for_other_notec_to_be_initialized

        mov byte [rdx + r14], IS_UNREAD ; Ustaw flagę, że moja wartość czeka na odebranie.

        lea rdx, [rel stack_top_value] ; Umieść wierzchołek stosu w tablicy.
        pop rax
        mov [rdx + r14*8], rax

        lea rdx, [rel waiting_for]     ; Oznacz gotowość na komunikację z Noteciem m.
        mov [rdx + r14*4], edi

.busy_wait_for_other_notec_to_want_to_communicate:
        mov eax, [rdx + rdi*4]         ; Czekaj aż Noteć m będzie gotowy na komunikację.
        cmp eax, r14d
        jne .busy_wait_for_other_notec_to_want_to_communicate

        lea rdx, [rel stack_top_value] ; Wczytaj wierzchołek stosu Notecia m.
        mov rax, [rdx + rdi*8]
        push rax

        lea rdx, [rel waiting_for]     ; Oznacz brak gotowości na komunikację.
        mov dword [rdx + rdi*4], INVALID_NOTEC_ID

        lea rdx, [rel notec_exchange_state] ; Poinformuj Notecia m o zakończeniu komunikacji.
        mov byte [rdx + rdi], IS_READ

.wait_for_my_value_to_be_read:
        mov al, [rdx + r14]            ; Poczekaj aż Noteć m zakończy komunikację.
        cmp al, IS_READ
        jne .wait_for_my_value_to_be_read

        jmp .loop_over_instructions

.exit:
        pop rax                        ; Zdejmujemy ostatni element, który został na stosie.
        mov rsp, rbp                   ; Zwalniamy resztę pamięci zajmowanej przez stos Notecia.
        pop r15                        ; Dla zgodności z ABI przywracamy rejestry r12-r15 i rbp.
        pop r14
        pop r13
        pop r12
        pop rbp
        ret
