if exists("b:current_syntax")
  finish
endif

syntax match gitdiffRemoval "\v^-.*$"
syntax match gitdiffAddition "\v^+.*$"

highlight link gitdiffRemoval Keyword
highlight link gitdiffAddition Exception

let b:current_syntax = "gitdiff"
