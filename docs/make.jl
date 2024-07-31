using SequenceTokenizers
using Documenter

DocMeta.setdocmeta!(SequenceTokenizers, :DocTestSetup, :(using SequenceTokenizers); recursive=true)

makedocs(;
    modules=[SequenceTokenizers],
    authors="Mateusz Kaduk <mateusz.kaduk@gmail.com> and contributors",
    sitename="SequenceTokenizers.jl",
    format=Documenter.HTML(;
        canonical="https://mashu.github.io/SequenceTokenizers.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mashu/SequenceTokenizers.jl",
    devbranch="main",
)
