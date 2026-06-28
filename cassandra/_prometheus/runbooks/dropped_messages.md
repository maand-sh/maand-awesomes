## Dropped messages

1. Identify which message types are dropped in the metrics labels
2. Check for overload: thread pool blocked alerts, high CPU, or disk saturation
3. Review `docker logs cassandra` for hints about backpressure or overload
4. Consider increasing relevant thread pool sizes or reducing client load
