; autor Jakub Molinski 419502

        default rel

        PUSH_MODE equ 0
        NUMBER_INSERT_MODE equ 1
        MAX_HEX_DIGIT_VALUE equ 15

        IS_UNREAD equ 1
        IS_READ equ 0

        global notec
        extern debug

        section .bss
        align 16

; 1. czy wartosc odczytana 2. wartosc top stosu 3. na kogo czekam

        czy_zainicjowane resq N
        czy_odczytana resq N
        top_stosu resq N
        na_kogo_czekam resq N

        section .text

notec:
        push rbp
        push r13                       ; Dla zgodności z ABI zapisujemy rejestry r13-r15.
        push r14
        push r15
        mov rbp, rsp                   ; Zapisuję ades powrotu.
        mov r14d, edi                  ; r14 - n
        mov r15, rsi                   ; r15 - adres ciągu instrukcji

        mov edi, r14d
        shl rdi, 3

        lea rdx, [na_kogo_czekam]
        add rdx, rdi
        mov dword [rdx], -1

        lea rdx, [czy_zainicjowane]
        add rdx, rdi
        mov dword [rdx], 1

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
        mov edx, eax
        sub dl, '0'
        cmp dl, 9
        cmovbe eax, edx
        jbe .digit_handler
        cmp al, '='                    ; = – Wyjdź z trybu wpisywania liczby.
        je .loop_condition
        mov edx, eax
        sub dl, 'A'                    ; Przesunięcie aby litery A..F miały wartości 10..15.
        add dl, 10
        cmp dl, MAX_HEX_DIGIT_VALUE
        cmovbe eax, edx
        jbe .digit_handler
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
        jbe .digit_handler
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

;g – Wywołaj (zaimplementowaną gdzieś indziej w języku C lub Asemblerze) funkcję:
.call_debug:
        mov edi, r14d
        mov rsi, rsp
        call debug                     ; Umieszcza w rax o ile pozycji przesunąć stos.
        lea rsp, [rsp + 8*rax]
        jmp .loop_over_instructions

; W – Zdejmij wartość ze stosu, potraktuj ją jako numer instancji Notecia m.
; Czekaj na operację W Notecia m ze zdjętym ze stosu numerem instancji Notecia n i zamień wartości na wierzchołkach stosów Noteci m i n.
.exchange_with_other_machine:
        pop rdi                        ; Numer notecia m.

;.busy_wait:
; xchg [rdx], eax                ; Jeśli blokada otwarta, zamknij ją.
; test eax, eax                  ; Sprawdź, czy blokada była otwarta.
; jnz .busy_wait                 ; Skocz, gdy blokada była zamknięta.

        mov esi, r14d
        shl rsi, 3
        mov ecx, edi
        shl ecx, 3

; poczekaj aż ten drugi zostanie zainicjowany
        lea rdx, [czy_zainicjowane]
        add rdx, rcx
.busy_wait_for_other_notec_to_be_initialized:
        mov eax, [rdx]
        test eax, eax
        jz .busy_wait_for_other_notec_to_be_initialized

; ustaw mi flage że moja wartość stosowa nieodczytana (czekaj aż będzie się dało to zrobić)
        lea rdx, [czy_odczytana]
        add rdx, rsi
        mov dword [rdx], IS_UNREAD

; wstaw moją wartość to mojej komóreczki publicznej
        lea rdx, [top_stosu]
        add rdx, rsi
        pop rax
        mov [rdx], rax

; ustaw mi flage że czekam na drugiego (m-tego)
        lea rdx, [na_kogo_czekam]      ; Adres flagi obecnego notecia.
        add rdx, rsi

        mov [rdx], rdi

; kiedy ten drugi ma flage że czeka na mnie wczytuje jego wartość
        lea rdx, [na_kogo_czekam]      ; Czy ten drugi czeka na mnie?
        add rdx, rcx
.busy_wait_for_other_notec_to_want_to_communicate:
        mov eax, [rdx]
        cmp eax, r14d
        jne .busy_wait_for_other_notec_to_want_to_communicate
        lea rdx, [top_stosu]           ; Top stosu tego drugiego.
        add rdx, rcx
        mov rax, [rdx]
        push rax

; oznaczam mu że przeczytałem jego wartość
        lea rdx, [na_kogo_czekam]
        add rdx, rcx
        mov dword [rdx], -1            ; ustawienie nieprawidłowego oczekiwania
        lea rdx, [czy_odczytana]
        add rdx, rcx
        mov byte [rdx], IS_READ

; on idzie dalej kiedy zobaczy że jego wartość odczytana

        lea rdx, [czy_odczytana]
        add rdx, rsi
.wait_for_my_value_to_be_read:
        mov eax, [rdx]
        cmp eax, IS_READ
        jne .wait_for_my_value_to_be_read

        jmp .loop_over_instructions

; 0 to 9, A to F, a to f – Znak jest interpretowany jako cyfra w zapisie przy podstawie 16.
; Jeśli Noteć jest w trybie wpisywania liczby, to liczba na wierzchołku stosu jest przesuwana o jedną pozycję
; w lewo i uzupełniania na najmniej znaczącej pozycji podaną cyfrą. Jeśli Noteć nie jest w trybie wpisywania liczby,
; to na wierzchołek stosu jest wstawiana wartość podanej cyfry. Noteć przechodzi w tryb wpisywania liczby
; po wczytaniu jednego ze znaków z tej grupy, a wychodzi z trybu wpisywania liczby po wczytaniu dowolnego znaku
; nie należącego to tej grupy.
.digit_handler:
        cmp r13d, NUMBER_INSERT_MODE
        je .digit_handler_shift_mode
        mov r13d, NUMBER_INSERT_MODE
        push rax
        jmp .exit_digit_handler
.digit_handler_shift_mode:
        pop rdi
        shl rdi, 4
        or rdi, rax
        push rdi
.exit_digit_handler:
        jmp .loop_condition_without_setting_push_mode

.exit:
        pop rax                        ; zdejmujemy ostatni element który został na stosie
        mov rsp, rbp
        pop r15                        ; Dla zgodności z ABI przywracamy rejestry r13-r15.
        pop r14
        pop r13
        pop rbp
        ret
