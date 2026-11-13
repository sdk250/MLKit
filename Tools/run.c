#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <grp.h>

int32_t main(int32_t argc, char *const *argv)
{
    if (argc < 3)
    {
        fprintf(stderr, "Usage: %s <gid> <command> [args...]\n", argv[0]);
        return 1;
    }

    __gid_t target = atoi(argv[1]);
    if (setgid(target) != 0)
    {
        perror("Setgid");
        return 1;
    }
    if (setuid(0) != 0)
    {
        perror("Setuid");
        return 1;
    }
    execvp(argv[2], argv + 2);

    fprintf(stderr, "Failed to exec '%s': %s\n", argv[2], strerror(errno));
    return 127;
}
