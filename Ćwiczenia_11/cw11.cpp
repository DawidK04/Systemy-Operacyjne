#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cerrno>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <pthread.h>
#include <cmath>
#include <thread>
#include <iostream>
#include <vector>

struct Shared {
    pthread_mutex_t mutex;
    unsigned int counts[26];
    double sum;
};

static void perror_exit(const char* msg) {
    perror(msg);
    exit(EXIT_FAILURE);
}

int main(int argc, char** argv) {
    if (argc < 2) {
        std::fprintf(stderr, "Usage: %s <ascii-file> [num_processes]\n", argv[0]);
        return 2;
    }

    const char* path = argv[1];
    unsigned int nproc = 0;
    if (argc >= 3) {
        long v = std::strtol(argv[2], nullptr, 10);
        if (v <= 0) {
            std::fprintf(stderr, "Invalid process count '%s'\n", argv[2]);
            return 2;
        }
        nproc = (unsigned int)v;
    } else {
        unsigned int h = std::thread::hardware_concurrency();
        nproc = (h == 0 ? 1u : h);
    }
    if (nproc < 1) nproc = 1;

    int fd = open(path, O_RDONLY);
    if (fd == -1) perror_exit("open");

    struct stat st;
    if (fstat(fd, &st) == -1) perror_exit("fstat");
    off_t filesize = st.st_size;

    if (filesize == 0) {
        std::puts("File is empty. Nothing to do.");
        close(fd);
        return 0;
    }

    void* file_map = mmap(nullptr, filesize, PROT_READ, MAP_SHARED, fd, 0);
    if (file_map == MAP_FAILED) perror_exit("mmap file");

    size_t shared_size = sizeof(Shared);
    void* shm = mmap(nullptr, shared_size, PROT_READ | PROT_WRITE,
                     MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (shm == MAP_FAILED) perror_exit("mmap shared");

    Shared* shared = reinterpret_cast<Shared*>(shm);

    for (int i = 0; i < 26; ++i) shared->counts[i] = 0;
    shared->sum = 0.0;

    pthread_mutexattr_t mattr;
    if (pthread_mutexattr_init(&mattr) != 0) perror_exit("pthread_mutexattr_init");
    if (pthread_mutexattr_setpshared(&mattr, PTHREAD_PROCESS_SHARED) != 0)
        perror_exit("pthread_mutexattr_setpshared");
    if (pthread_mutex_init(&shared->mutex, &mattr) != 0)
        perror_exit("pthread_mutex_init");
    pthread_mutexattr_destroy(&mattr);

    std::vector<off_t> starts(nproc), ends(nproc);
    for (unsigned int i = 0; i < nproc; ++i) {
        starts[i] = (filesize * i) / nproc;
        ends[i]   = (filesize * (i + 1)) / nproc;
    }

    std::vector<pid_t> children;
    children.reserve(nproc);
    unsigned char* data = static_cast<unsigned char*>(file_map);

    for (unsigned int i = 0; i < nproc; ++i) {
        pid_t pid = fork();
        if (pid == -1) {
            perror("fork");
            break;
        }
        if (pid == 0) {
            off_t s = starts[i];
            off_t e = ends[i];
            unsigned int local_counts[26] = {0};
            double local_sum = 0.0;

            for (off_t pos = s; pos < e; ++pos) {
                unsigned char c = data[pos];
                local_sum += std::sqrt((double)c);
                if (c >= 'A' && c <= 'Z') local_counts[c - 'A']++;
                else if (c >= 'a' && c <= 'z') local_counts[c - 'a']++;
            }

            if (pthread_mutex_lock(&shared->mutex) != 0) _exit(3);
            for (int k = 0; k < 26; ++k) shared->counts[k] += local_counts[k];
            shared->sum += local_sum;
            pthread_mutex_unlock(&shared->mutex);
            _exit(0);
        } else {
            children.push_back(pid);
        }
    }

    int status = 0;
    for (pid_t ch : children) {
        pid_t w = waitpid(ch, &status, 0);
        if (w == -1) perror("waitpid");
    }

    std::printf("Letter counts (a..z):\n");
    for (int k = 0; k < 26; ++k)
        std::printf("%c: %u\n", 'a' + k, shared->counts[k]);
    std::printf("Sum of sqrt(ascii) over all bytes: %.10f\n", shared->sum);

    pthread_mutex_destroy(&shared->mutex);
    munmap(shm, shared_size);
    munmap(file_map, filesize);
    close(fd);
    return 0;
}
