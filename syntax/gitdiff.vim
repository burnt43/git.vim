if exists("b:current_syntax")
  finish
endif

syntax region gitdiffRemoval start=/\v^-/ end=/\v$/
syntax region gitdiffAddition start=/\v^+/ end=/\v$/

highlight link gitdiffRemoval Keyword
highlight link gitdiffAddition Exception

let b:current_syntax = "gitdiff"
