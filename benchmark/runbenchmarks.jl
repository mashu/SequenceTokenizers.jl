using PkgBenchmark

results = benchmarkpkg(dirname(@__DIR__), retune=true)
export_markdown("benchmark_results.md", results)