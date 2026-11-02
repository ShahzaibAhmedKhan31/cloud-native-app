import concurrent.futures
import requests
import time
from collections import Counter

URL = "https://cloud-native-app.alphabridge.dev/health"
CONCURRENT_REQUESTS = 40
DURATION_SECONDS = 300  # 5 minutes
LOG_INTERVAL = 5        # Log progress every 5 seconds

def make_request():
    start = time.time()
    try:
        response = requests.get(URL, timeout=5)
        latency = (time.time() - start) * 1000  # ms
        return response.status_code, latency
    except Exception as e:
        latency = (time.time() - start) * 1000
        return f"Error: {type(e).__name__}", latency

def run_load_test():
    print("=" * 70)
    print(f"🚀 STARTING LOAD TEST")
    print(f"   Target URL:          {URL}")
    print(f"   Concurrent Workers:  {CONCURRENT_REQUESTS}")
    print(f"   Duration:            {DURATION_SECONDS} seconds ({DURATION_SECONDS // 60} minutes)")
    print(f"   Logging Interval:    Every {LOG_INTERVAL} seconds")
    print("=" * 70)

    start_time = time.time()
    end_time = start_time + DURATION_SECONDS
    last_log_time = start_time

    total_requests = 0
    status_counts = Counter()
    total_latency = 0.0

    # Interval tracking for current RPS
    interval_requests = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=CONCURRENT_REQUESTS) as executor:
        while time.time() < end_time:
            # Dispatch a batch of concurrent requests equal to worker count
            futures = [executor.submit(make_request) for _ in range(CONCURRENT_REQUESTS)]
            
            for future in concurrent.futures.as_completed(futures):
                status, latency = future.result()
                total_requests += 1
                interval_requests += 1
                status_counts[status] += 1
                total_latency += latency

            current_time = time.time()
            # Log progress every LOG_INTERVAL seconds
            if current_time - last_log_time >= LOG_INTERVAL:
                elapsed = current_time - start_time
                remaining = max(0, DURATION_SECONDS - elapsed)
                interval_duration = current_time - last_log_time
                current_rps = interval_requests / interval_duration if interval_duration > 0 else 0
                avg_latency = total_latency / total_requests if total_requests > 0 else 0

                ok_count = status_counts.get(200, 0)
                err_count = sum(count for status, count in status_counts.items() if status != 200)

                print(
                    f"⏱️  [{int(elapsed):3d}s elapsed | {int(remaining):3d}s left] "
                    f"Requests: {total_requests:6,d} | "
                    f"RPS: {current_rps:5.1f} req/s | "
                    f"200 OK: {ok_count:6,d} | "
                    f"Errors: {err_count:3,d} | "
                    f"Avg Latency: {avg_latency:5.1f}ms"
                )

                # Reset interval counter
                interval_requests = 0
                last_log_time = current_time

    # Final Summary Report
    total_elapsed = time.time() - start_time
    overall_rps = total_requests / total_elapsed if total_elapsed > 0 else 0
    avg_latency = total_latency / total_requests if total_requests > 0 else 0

    print("=" * 70)
    print("✅ LOAD TEST COMPLETED")
    print("=" * 70)
    print(f"Total Time Elapsed:    {total_elapsed:.2f} seconds")
    print(f"Total Requests Sent:   {total_requests:,}")
    print(f"Average RPS:           {overall_rps:.2f} req/s")
    print(f"Average Latency:       {avg_latency:.2f} ms")
    print("\nStatus Code Distribution:")
    for status, count in status_counts.items():
        percentage = (count / total_requests) * 100
        print(f"   - {status}: {count:,} ({percentage:.2f}%)")
    print("=" * 70)

if __name__ == "__main__":
    run_load_test()