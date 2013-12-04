#include <dispatch/dispatch.h>
#include <stdio.h>

static void timer_did_fire(void *context) { printf("Strawberry fields...\n"); }

static void write_completion_handler(dispatch_data_t unwritten_data, int error, void *context) {
    if (!unwritten_data && error == 0)
       printf("Dispatch I/O wrote everything to stdout. Hurrah.\n");
}

static void read_completion_handler(dispatch_data_t data, int error, void *context) {
    int fd = (intptr_t)context;
    close(fd);

    dispatch_write_f_np(STDOUT_FILENO, data, dispatch_get_main_queue(),
                        NULL, write_completion_handler);
}

int main(int argc, const char *argv[]) {
    dispatch_source_t timer = dispatch_source_create(
        DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());

    dispatch_source_set_event_handler_f(timer, timer_did_fire);
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC,
                              0.5 * NSEC_PER_SEC);
    dispatch_resume(timer);

    int fd = open("dispatch_test.c", O_RDONLY);

    dispatch_read_f_np(fd, SIZE_MAX, dispatch_get_main_queue(), (void *)(intptr_t)fd,
                    read_completion_handler);

    dispatch_main();
    return 0;
}
