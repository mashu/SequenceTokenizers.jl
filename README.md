# SequenceTokenizers.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mashu.github.io/SequenceTokenizers.jl/dev/)
[![Build Status](https://github.com/mashu/SequenceTokenizers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mashu/SequenceTokenizers.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mashu/SequenceTokenizers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mashu/SequenceTokenizers.jl)
[![Benchmarks](https://img.shields.io/badge/benchmarks-view%20results-blue)](https://github.com/mashu/SequenceTokenizers.jl/actions?query=workflow%3ABenchmarks)

SequenceTokenizers.jl is a Julia package that offers a simple and efficient way to tokenize character sequences. It provides a `SequenceTokenizer` struct that can:

- Convert characters to integer tokens based on a predefined alphabet
- Handle unknown characters with a customizable unknown symbol
- Tokenize single characters, arrays of characters, and batches of sequences with **variable length**
- Convert token indices back to characters
- Create one-hot encoded representations of tokenized sequences
- Convert one-hot encoded representations back to characters

## Features

- Customizable alphabet and unknown symbol
- Efficient lookup using vector
- Batch processing capabilities
- One-hot encoding and decoding support
- Minimal dependency

> :blue_book: **Note**
> It is not a [Flux](https://fluxml.ai/Flux.jl) layer to keep dependencies minimal, therefore it cannot be placed inside a gradient block.

## Usage

```julia
using SequenceTokenizers

alphabet = ['A', 'C', 'G', 'T']
tokenizer = SequenceTokenizer(alphabet, 'N')  # 'N' is the unknown symbol

# Tokenize a single character
tokenizer('A')  # Returns 2 (index in the alphabet)

# Tokenize a sequence
tokenizer(['A', 'C', 'T', 'X'])  # Returns [2, 3, 5, 1] ('X' is unknown, so it gets the index of 'N')

# Convert token back to character
tokenizer(2)  # Returns 'A'

# Create a batch of sequences
batch = Int32[2 4; 3 5; 1 2]  # Represents ['A', 'G'; 'C', 'T'; 'N', 'A']

# Create one-hot encoded representation
onehot_encoded = onehot_batch(tokenizer, batch)

# Convert one-hot encoded representation back to characters
decoded_batch = onecold_batch(tokenizer, onehot_encoded)
# Returns ['A' 'G'; 'C' 'T'; 'N' 'A']
```

This package is useful for natural language processing tasks, sequence modeling, and any application that requires mapping between characters and integer tokens or one-hot encoded representations.
