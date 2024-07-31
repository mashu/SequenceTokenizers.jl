using SequenceTokenizers
using BenchmarkTools

SUITE = BenchmarkGroup()
TEST_ALPHABET = collect("ACGT")
TEST_BATCH = collect.(["ACGTACGT", "TGCATGCA", "ATATATATA", "GCGCGCGC", "ACGTACGTACGT"])
SUITE["tokenize_batch"] = @benchmarkable sequence_tokenizer($TEST_BATCH) setup = begin
    sequence_tokenizer = SequenceTokenizer($TEST_ALPHABET, 'N')
end
