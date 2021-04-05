#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <pthread.h>

#define ITERATIONS 10000

extern uint64_t notec(uint32_t n, char const *calc);
int64_t debug(uint32_t n, uint64_t *stack_pointer) {
    (void)n;
    (void)stack_pointer;
    return 0;
}

void *thread1() {
    char buf[128];
    uint64_t x;
    for (uint64_t i = 0; i < ITERATIONS; i++) {
        sprintf(buf, "%lx=2W", 1234+i);
        x = notec(1, buf);
        if (x != 1337 + i)
            abort();
        sprintf(buf, "%lx=3W", 2345+i);
        x = notec(1, buf);
        if (x != 2137 + i)
            abort();
    }
    return NULL;
}
void *thread2() {
    char buf[128];
    for (uint64_t i = 0; i < ITERATIONS; i++) {
        sprintf(buf, "%lx=1W", 1337+i);
        uint64_t x = notec(2, buf);
        if (x != 1234 + i)
            abort();
    }
    return NULL;
}
void *thread3() {
    char buf[128];
    for (uint64_t i = 0; i < ITERATIONS; i++) {
        sprintf(buf, "%lx=1W", 2137+i);
        uint64_t x = notec(3, buf);
        if (x != 2345 + i)
            abort();
    }
    return NULL;
}

int main() {
    pthread_t t1, t2, t3;
    pthread_create(&t1, NULL, thread1, NULL);
    pthread_create(&t2, NULL, thread2, NULL);
    pthread_create(&t3, NULL, thread3, NULL);
    pthread_join(t1, NULL);
    pthread_join(t2, NULL);
    pthread_join(t3, NULL);
    return 0;
}
