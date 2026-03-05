#!/usr/bin/env bash
set -euo pipefail

RESULTS_DIR="${RESULTS_DIR:-$HOME/benchmarks/$(hostname)/$(date +%Y%m%d-%H%M%S)}"
THREADS=$(nproc)

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[0;36m'
bold='\033[1m'
reset='\033[0m'

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [SUITES...]

Run system benchmarks and save results to ${bold}RESULTS_DIR${reset}.

Suites:
  cpu        CPU stress and compute (stress-ng, sysbench)
  memory     Memory bandwidth and integrity (sysbench, memtester)
  disk       Storage I/O (fio)
  network    Network throughput (iperf3, requires remote server)
  gpu        GPU rendering (glmark2, unigine-heaven)
  all        Run all suites (default)

Options:
  -o DIR     Output directory (default: ~/benchmarks/<host>/<timestamp>)
  -t N       Thread count (default: all cores, currently $THREADS)
  -s HOST    iperf3 server address (required for network suite)
  -d DEVICE  Disk device/path for fio tests (default: \$RESULTS_DIR/fio-test)
  -m SIZE    memtester size in MB (default: 256)
  -h         Show this help

Examples:
  $(basename "$0")                    # run all suites
  $(basename "$0") cpu disk           # run CPU and disk only
  $(basename "$0") -t 8 cpu           # CPU with 8 threads
  $(basename "$0") -s 10.0.0.1 network
EOF
    exit 0
}

log()  { echo -e "${cyan}[bench]${reset} $*"; }
warn() { echo -e "${yellow}[warn]${reset} $*"; }
err()  { echo -e "${red}[error]${reset} $*" >&2; }
header() { echo -e "\n${bold}${green}=== $* ===${reset}\n"; }

require() {
    for cmd in "$@"; do
        if ! command -v "$cmd" &>/dev/null; then
            err "'$cmd' not found in PATH. Is the benchmarking module enabled?"
            exit 1
        fi
    done
}

save() {
    local name="$1"
    local file="$RESULTS_DIR/$name"
    cat > "$file"
    log "Saved ${bold}$name${reset} ($(wc -l < "$file") lines)"
}

IPERF_SERVER=""
FIO_TARGET=""
MEMTEST_SIZE=256
SUITES=()

while getopts "o:t:s:d:m:h" opt; do
    case $opt in
        o) RESULTS_DIR="$OPTARG" ;;
        t) THREADS="$OPTARG" ;;
        s) IPERF_SERVER="$OPTARG" ;;
        d) FIO_TARGET="$OPTARG" ;;
        m) MEMTEST_SIZE="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [[ $# -eq 0 ]]; then
    SUITES=(cpu memory disk gpu)
else
    SUITES=("$@")
fi

# Expand "all"
if [[ " ${SUITES[*]} " == *" all "* ]]; then
    SUITES=(cpu memory disk network gpu)
fi

mkdir -p "$RESULTS_DIR"
log "Results directory: ${bold}$RESULTS_DIR${reset}"
log "Threads: $THREADS"
log "Suites: ${SUITES[*]}"

# ---------------------------------------------------------------------------
# CPU
# ---------------------------------------------------------------------------
bench_cpu() {
    header "CPU Benchmarks"
    require stress-ng sysbench

    log "stress-ng: matrix method ($THREADS workers, 30s)..."
    stress-ng --matrix "$THREADS" --timeout 30s --metrics-brief 2>&1 | save cpu-stressng-matrix.txt

    log "stress-ng: cpu method ($THREADS workers, 30s)..."
    stress-ng --cpu "$THREADS" --timeout 30s --metrics-brief 2>&1 | save cpu-stressng-cpu.txt

    log "sysbench: prime numbers (threads=$THREADS, 30s)..."
    sysbench cpu --threads="$THREADS" --time=30 run 2>&1 | save cpu-sysbench.txt

    log "sysbench: single-thread prime numbers (30s)..."
    sysbench cpu --threads=1 --time=30 run 2>&1 | save cpu-sysbench-single.txt
}

# ---------------------------------------------------------------------------
# Memory
# ---------------------------------------------------------------------------
bench_memory() {
    header "Memory Benchmarks"
    require sysbench memtester

    log "sysbench: memory read (threads=$THREADS, 30s)..."
    sysbench memory --threads="$THREADS" --time=30 --memory-oper=read run 2>&1 | save mem-sysbench-read.txt

    log "sysbench: memory write (threads=$THREADS, 30s)..."
    sysbench memory --threads="$THREADS" --time=30 --memory-oper=write run 2>&1 | save mem-sysbench-write.txt

    log "memtester: ${MEMTEST_SIZE}MB, 1 iteration..."
    if [[ $EUID -eq 0 ]]; then
        memtester "${MEMTEST_SIZE}M" 1 2>&1 | save mem-memtester.txt
    else
        sudo memtester "${MEMTEST_SIZE}M" 1 2>&1 | save mem-memtester.txt
    fi
}

# ---------------------------------------------------------------------------
# Disk
# ---------------------------------------------------------------------------
bench_disk() {
    header "Disk I/O Benchmarks"
    require fio

    local fio_dir="${FIO_TARGET:-$RESULTS_DIR/fio-test}"
    mkdir -p "$fio_dir"

    log "fio: sequential read (4 jobs, 1GB)..."
    fio --name=seq-read --directory="$fio_dir" \
        --rw=read --bs=1M --size=1G --numjobs=4 \
        --runtime=30 --time_based --group_reporting \
        --output-format=normal 2>&1 | save disk-fio-seq-read.txt

    log "fio: sequential write (4 jobs, 1GB)..."
    fio --name=seq-write --directory="$fio_dir" \
        --rw=write --bs=1M --size=1G --numjobs=4 \
        --runtime=30 --time_based --group_reporting \
        --output-format=normal 2>&1 | save disk-fio-seq-write.txt

    log "fio: random read (4 jobs, 4K blocks)..."
    fio --name=rand-read --directory="$fio_dir" \
        --rw=randread --bs=4k --size=1G --numjobs=4 \
        --runtime=30 --time_based --group_reporting \
        --output-format=normal 2>&1 | save disk-fio-rand-read.txt

    log "fio: random write (4 jobs, 4K blocks)..."
    fio --name=rand-write --directory="$fio_dir" \
        --rw=randwrite --bs=4k --size=1G --numjobs=4 \
        --runtime=30 --time_based --group_reporting \
        --output-format=normal 2>&1 | save disk-fio-rand-write.txt

    rm -rf "$fio_dir"
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
bench_network() {
    header "Network Benchmarks"
    require iperf3

    if [[ -z "$IPERF_SERVER" ]]; then
        warn "No iperf3 server specified (-s HOST). Skipping network suite."
        warn "Start a server on another machine with: iperf3 -s"
        return
    fi

    log "iperf3: TCP upload to $IPERF_SERVER (30s)..."
    iperf3 -c "$IPERF_SERVER" -t 30 -P "$THREADS" 2>&1 | save net-iperf3-upload.txt

    log "iperf3: TCP download from $IPERF_SERVER (30s)..."
    iperf3 -c "$IPERF_SERVER" -t 30 -P "$THREADS" -R 2>&1 | save net-iperf3-download.txt

    log "iperf3: UDP upload to $IPERF_SERVER (30s)..."
    iperf3 -c "$IPERF_SERVER" -t 30 -u -b 0 2>&1 | save net-iperf3-udp.txt
}

# ---------------------------------------------------------------------------
# GPU
# ---------------------------------------------------------------------------
bench_gpu() {
    header "GPU Benchmarks"

    if ! command -v glmark2 &>/dev/null && ! command -v unigine-heaven &>/dev/null; then
        warn "No GPU benchmark tools found (glmark2, unigine-heaven). Skipping."
        return
    fi

    if command -v glmark2 &>/dev/null; then
        log "glmark2: Wayland..."
        if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            glmark2-wayland 2>&1 | save gpu-glmark2.txt
        elif [[ -n "${DISPLAY:-}" ]]; then
            glmark2 2>&1 | save gpu-glmark2.txt
        else
            warn "No display server detected. Skipping glmark2."
        fi
    fi

    if command -v unigine-heaven &>/dev/null; then
        log "unigine-heaven: launch manually from the results directory."
        echo "Run: unigine-heaven" | save gpu-unigine-heaven-note.txt
    fi

    if command -v unigine-valley &>/dev/null; then
        log "unigine-valley: launch manually from the results directory."
        echo "Run: unigine-valley" | save gpu-unigine-valley-note.txt
    fi
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
generate_summary() {
    header "Summary"
    {
        echo "Benchmark run: $(date -Iseconds)"
        echo "Host: $(hostname)"
        echo "Kernel: $(uname -r)"
        echo "CPU: $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | xargs)"
        echo "Cores: $THREADS"
        echo "Memory: $(free -h | awk '/^Mem:/{print $2}')"
        echo "Suites: ${SUITES[*]}"
        echo ""
        echo "Results saved to: $RESULTS_DIR"
        echo ""
        echo "Files:"
        ls -1 "$RESULTS_DIR" | grep -v '^fio-test$' || true
    } | tee "$RESULTS_DIR/summary.txt"
}

# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------
for suite in "${SUITES[@]}"; do
    case "$suite" in
        cpu)     bench_cpu ;;
        memory)  bench_memory ;;
        disk)    bench_disk ;;
        network) bench_network ;;
        gpu)     bench_gpu ;;
        all)     ;; # already expanded
        *)       err "Unknown suite: $suite"; usage ;;
    esac
done

generate_summary
log "Done. All results in ${bold}$RESULTS_DIR${reset}"
