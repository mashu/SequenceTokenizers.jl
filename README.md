# SequenceTokenizers.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mashu.github.io/SequenceTokenizers.jl/dev/)
[![Build Status](https://github.com/mashu/SequenceTokenizers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mashu/SequenceTokenizers.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mashu/SequenceTokenizers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mashu/SequenceTokenizers.jl)
[![Benchmarks](https://img.shields.io/badge/benchmarks-view%20results-blue)](https://github.com/mashu/SequenceTokenizers.jl/actions?query=workflow%3ABenchmarks)

SequenceTokenizers.jl is a Julia convenience package that offers a simplified and efficient way to tokenize character sequences, wrapping functionality from [OneHotArrays](https://github.com/FluxML/OneHotArrays.jl) while handling `String` sequences and padding automatically. It provides a SequenceTokenizer struct that can:

- Convert characters to integer tokens based on a predefined alphabet
- Handle unknown characters with a customizable unknown symbol
- Tokenize single characters, arrays of characters, and batches of sequences with **variable length** with automatic padding
- Convert token indices back to characters
- Create one-hot encoded representations of tokenized sequences
- Convert one-hot encoded representations back to characters

> :blue_book: **Limitations**
> - It is not a [Flux](https://fluxml.ai/Flux.jl) layer to keep dependencies minimal, therefore it cannot be placed inside a gradient block.
> - Single characters must be Char type
> - Multiple character sequences must be String type
> - No mixed type arrays are supported, it's either Strings or Chars that produce correct behaviour

## Usage

```julia
using SequenceTokenizers

# Create tokenizer
alphabet = ['A', 'C', 'G', 'T']
tokenizer = SequenceTokenizer(alphabet, 'N')  # 'N' is the unknown symbol

# Tokenize sequences (perhaps most common use case)
tokens = tokenizer(["AGTCAGGACA","AGCGTGCGGGTAGGCTCGCC"])  # Returns UInt32[2 2; 4 4; 5 3; 3 4; 2 5; 4 4; 4 3; 2 4; 3 4; 2 4; 1 5; 1 2; 1 4; 1 4; 1 3; 1 5; 1 3; 1 4; 1 3; 1 3]

# Create a batch of sequences
batch = UInt32[2 2; 4 4; 5 3; 3 4; 2 5; 4 4; 4 3; 2 4; 3 4; 2 4; 1 5; 1 2; 1 4; 1 4; 1 3; 1 5; 1 3; 1 4; 1 3; 1 3]

# Create one-hot encoded representation
onehot_encoded = onehot_batch(tokenizer, batch)

# Convert one-hot encoded representation back to characters
decoded_batch = onecold_batch(tokenizer, onehot_encoded)
# Returns ['A' 'A'; 'G' 'G'; 'T' 'C'; 'C' 'G'; 'A' 'T'; 'G' 'G'; 'G' 'C'; 'A' 'G'; 'C' 'G'; 'A' 'G'; 'N' 'T'; 'N' 'A'; 'N' 'G'; 'N' 'G'; 'N' 'C'; 'N' 'T'; 'N' 'C'; 'N' 'G'; 'N' 'C'; 'N' 'C'] with N characters right padding shorter sequence

```

This package is useful for natural language processing tasks, sequence modeling, and any application that requires mapping between characters and integer tokens or one-hot encoded representations.
