#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>

extern uint64_t notec(uint32_t n, char const *calc);
int64_t debug(uint32_t n, uint64_t *stack_pointer) {
    (void)n;
    (void)stack_pointer;
    return 0;
}

const char *NUMBER_CHARS = "0123456789abcdefABCDEF";

int main() {
    const size_t size = 1024 * 1024 * 1024;
    const int limit_stack_size = 512 * 1024;
    clock_t begin, end;

    srand(1337);

    char *buf = malloc(size);
    for (size_t i = 0; i < size; i++) {
        buf[i] = NUMBER_CHARS[rand() % 10];
    }

    // https://stackoverflow.com/a/5249150
    printf("Number test time: ");
    begin = clock();
    notec(0, buf);
    end = clock();
    printf("%lfs\n", (double)(end - begin) / CLOCKS_PER_SEC);

    int stack_size = 0;
    int max_stack_size = 0;
    int parse_mode = 0;
    for (size_t i = 0; i < size; i++) {
        if (stack_size > max_stack_size)
            max_stack_size = stack_size;
        if (stack_size >= limit_stack_size) {
            buf[i] = 'Z';
            --stack_size;
            parse_mode = 0;
            continue;
        }
        int x = rand() % 8;
        if (x == 0) {
            buf[i] = "Nn"[rand() % 2];
            ++stack_size;
            parse_mode = 0;
        } else if (x == 1 && stack_size > 0) {
            buf[i] = "-~"[rand() % 2];
            parse_mode = 0;
        } else if (x == 2 && stack_size > 0) {
            buf[i] = 'Z';
            --stack_size;
            parse_mode = 0;
        } else if (x == 3 && stack_size > 0) {
            buf[i] = 'Y';
            ++stack_size;
            parse_mode = 0;
        } else if (x == 4 && stack_size > 1) {
            buf[i] = "+*&|^"[rand() % 5];
            --stack_size;
            parse_mode = 0;
        } else if (x == 5 && stack_size > 1) {
            buf[i] = 'X';
            parse_mode = 0;
        } else {
//            buf[i] = NUMBER_CHARS[rand() % 10]; - we do not need to this since it was set up by the previous test to a number
            if (!parse_mode) {
                stack_size++;
                parse_mode = 1;
            }
        }
    }
    printf("Max stack size for chaos test: %d\n", max_stack_size);

    printf("Chaos test time: ");
    begin = clock();
    notec(0, buf);
    end = clock();
    printf("%lfs\n", (double)(end - begin) / CLOCKS_PER_SEC);

    return 0;
}