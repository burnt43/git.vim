" private functions {{{
function! git#FindGitRepo()
  let current_directory = fnamemodify(bufname("%"), ":p:h")
  
  while current_directory !=# '/'
    if !empty(glob(current_directory . '/' . '.git'))
      return current_directory
    else
      let current_directory = fnamemodify(current_directory, ":h")
    endif
  endwhile

  return -1
endfunction

function! git#FindBufferNameRelativeToGitRepo(git_repo_directory)
  let full_path_of_buffer = fnamemodify(bufname("%"), ":p")

  return fnamemodify(full_path_of_buffer, ':s?' . a:git_repo_directory . '/??') 
endfunction

function! git#OpenOrFocusBuffer(buffer_name)
  let buffer_number = bufwinnr(buffer_name)
  echom "buffer_number: " . buffer_number

  if buffer_number >= 0
    execute buffer_number . "wincmd w"
  else
    execute "split " . a:buffer_name
  endif
endfunction

function! git#StoreCurrentDirectory()
  let g:git_current_directory = fnamemodify(bufname("%"), ":p:h")
endfunction

function! git#CdToStoredDirectory()
  if !empty(g:git_current_directory)
    execute "silent !cd " . g:git_current_directory
    redraw!
  end
endfunction
" }}}
" public functions {{{
function! git#GitDiff()
  write

  call git#StoreCurrentDirectory()
  let git_repo_directory = git#FindGitRepo()

  if git_repo_directory !=# -1
    let git_diff_result = system("cd " . git_repo_directory . "&& git diff " . git#FindBufferNameRelativeToGitRepo(git_repo_directory))

    if git_diff_result =~ '\v^Not a git repository'
      echoerr "not a git repo"
    else
      call git#OpenOrFocusBuffer('__Git_Diff__')

      normal! ggdG
      setlocal filetype=gitdiff
      setlocal buftype=nofile

      call append(0, split(git_diff_result, '\v\n'))
    end

    call git#CdToStoredDirectory()
  else
    echoerr "not a git repo"
  end
endfunction

function! git#GitRefresh()
  let current_directory  = fnamemodify(bufname("%"), ":p:h")
  let git_repo_directory = git#FindGitRepo()

  if git_repo_directory !=# -1
    execute "silent !cd " . git_repo_directory . " && git checkout " . git#FindBufferNameRelativeToGitRepo(git_repo_directory) . " && cd " . current_directory 
    edit
    redraw!
  else
    echoerr "not a git repo"
  endif
endfunction

function! git#GitCommit()
endfunction
" }}}
