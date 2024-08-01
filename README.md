# SequenceTokenizers.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://mashu.github.io/SequenceTokenizers.jl/dev/)
[![Build Status](https://github.com/mashu/SequenceTokenizers.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/mashu/SequenceTokenizers.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/mashu/SequenceTokenizers.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mashu/SequenceTokenizers.jl)
[![Benchmarks](https://img.shields.io/badge/benchmarks-view%20results-blue)](https://github.com/mashu/SequenceTokenizers.jl/actions?query=workflow%3ABenchmarks)

SequenceTokenizers.jl is a Julia package that offers a simple and efficient way to tokenize character sequences. It provides a `SequenceTokenizer` struct that can:

- Convert characters to integer tokens based on a predefined alphabet
- Handle unknown characters with a customizable unknown symbol
- Tokenize single characters, arrays of characters, and batches of sequences
- Convert token indices back to characters

## Features

- Customizable alphabet and unknown symbol
- Efficient lookup using a dictionary
- Batch processing capabilities
- Minimal dependency on Functors.jl and Optimisers.jl to define a layer

## Usage

```julia
using SequenceTokenizers

alphabet = ['a', 'b', 'c']
tokenizer = SequenceTokenizer(alphabet, '_')  # '_' is the unknown symbol

# Tokenize a single character
tokenizer('a')  # Returns 2 (index in the alphabet)

# Tokenize a sequence
tokenizer(['a', 'b', 'd'])  # Returns [2, 3, 1] ('d' is unknown, so it gets the index of '_')

# Convert token back to character
tokenizer(2)  # Returns 'a'
```

This package is useful for natural language processing tasks, sequence modeling, and any application that requires mapping between characters and integer tokens.
