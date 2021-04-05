#include <assert.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

// Przeniesienie liczby 2137 z notecia 0 do notecia N-1, przekazując liczbę po kolei sąsiadom.

uint64_t notec(uint32_t n, char const* calc);
int64_t debug(uint32_t n, uint64_t* stack_pointer);

volatile unsigned wait = 1;

static char calcs[N][10];

int64_t debug(uint32_t n, uint64_t* stack_pointer) {
    // printf("%lu\n", *stack_pointer);
    (void)n;
    assert(*stack_pointer == 2137);
    return 0;
}

void* thread_routine(void* data) {
    uint32_t n = *(uint32_t*)data;
    const char* calc;

    calc = calcs[n];

    while (wait)
        ;

    uint64_t result = notec(n, calc);
    // printf("num: %d, result %lu\n", n, result);

    if (n < N - 1) {
        assert(result == 0);
    } else {
        assert(result = 2137);
    }

    return NULL;
}

int main() {
    pthread_t tid[N];
    uint32_t n[N];
    strcpy(calcs[0], "859g1W");
    strcpy(calcs[N - 1], "0g1W");
    sprintf(calcs[N - 1], "0=%02XWg", N - 2);
    for (int i = 1; i < N - 1; i++) {
        sprintf(calcs[i], "0=%02XWg%02XW", i - 1, i + 1);
    }

    for (int i = N - 1; i >= 0; i--) {
        n[i] = i;
        // printf("%i started\n", i);
        assert(0 == pthread_create(&tid[i], NULL, &thread_routine, (void*)&n[i]));
    }

    wait = 0;

    for (int i = 0; i < N; ++i) {
        // printf("%d exited\n", i);
        assert(0 == pthread_join(tid[i], NULL));
    }

    return 0;
}
