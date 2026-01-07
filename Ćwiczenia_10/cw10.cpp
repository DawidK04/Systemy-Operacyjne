#include <bits/stdc++.h>
#include <thread>
#include <mutex>
#include <cmath>

#define LETTER_COUNT 26

struct context {
    std::string content;
    unsigned long count[LETTER_COUNT] = {0};
    double sumOfSquares = 0;
    std::mutex mutex;
};

void worker(context &ctx, size_t start, size_t end) {
    unsigned long local_count[LETTER_COUNT] = {0};
    double local_sum = 0.0;

    const std::string &s = ctx.content;
    for (size_t i = start; i < end; ++i) {
        unsigned char uc = static_cast<unsigned char>(s[i]);
        local_sum += std::sqrt(static_cast<double>(uc));

        unsigned char lower = static_cast<unsigned char>(std::tolower(uc));
        if (lower >= 'a' && lower <= 'z') {
            local_count[lower - 'a']++;
        }
    }

    {
        std::lock_guard<std::mutex> lock(ctx.mutex);
        for (int i = 0; i < LETTER_COUNT; ++i) ctx.count[i] += local_count[i];
        ctx.sumOfSquares += local_sum;
    }
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        return 1;
    }

    std::string path = argv[1];

    unsigned int numThreads = std::thread::hardware_concurrency();
    if (numThreads == 0) numThreads = 2;
    if (argc >= 3) {
        try {
            long nt = std::stol(argv[2]);
            if (nt >= 1) numThreads = static_cast<unsigned int>(nt);
        } catch (...) {
        }
    }

    std::ifstream in(path, std::ios::in | std::ios::binary);
    if (!in) {
        return 2;
    }
    std::string content;
    in.seekg(0, std::ios::end);
    content.reserve(static_cast<size_t>(in.tellg()));
    in.seekg(0, std::ios::beg);
    content.assign((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());

    context ctx;
    ctx.content = std::move(content);

    size_t total = ctx.content.size();
    if (total == 0) {
        std::cout << "Plik pusty.\n";
        return 0;
    }

    if (numThreads > total) numThreads = static_cast<unsigned int>(total);

    std::vector<std::thread> threads;
    threads.reserve(numThreads);

    size_t base = total / numThreads;
    size_t rem  = total % numThreads;

    size_t pos = 0;
    for (unsigned int i = 0; i < numThreads; ++i) {
        size_t chunk = base + (i < rem ? 1 : 0);
        size_t start = pos;
        size_t end = start + chunk;
        pos = end;
        threads.emplace_back(worker, std::ref(ctx), start, end);
    }

    for (auto &t : threads) if (t.joinable()) t.join();

    for (int i = 0; i < LETTER_COUNT; ++i) {
        char c = 'a' + i;
        std::cout << c << ": " << ctx.count[i] << '\n';
    }
    std::cout << "Suma pierwiastków: " << std::setprecision(15) << ctx.sumOfSquares << '\n';
    return 0;
}
