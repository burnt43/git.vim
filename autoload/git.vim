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
  let buffer_number = bufwinnr(a:buffer_name)

  if buffer_number >= 0
    execute buffer_number . "wincmd w"
  else
    execute "split " . a:buffer_name
  endif
endfunction
" }}}
" public functions {{{
function! git#GitDiff()
  write

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
  else
    echoerr "not a git repo"
  end
endfunction

function! git#GitRefresh()
  let git_repo_directory = git#FindGitRepo()

  if git_repo_directory !=# -1
    execute "silent !cd " . git_repo_directory . " && git checkout " . git#FindBufferNameRelativeToGitRepo(git_repo_directory)
    edit
    redraw!
  else
    echoerr "not a git repo"
  endif
endfunction

function! git#GitCommit()
  write

  let git_repo_directory = git#FindGitRepo()

  if git_repo_directory !=# -1
    call git#OpenOrFocusBuffer('__Git_Commit__')

    normal! ggdG
    setlocal filetype=gitcommit
    setlocal buftype=nofile
  else
    echoerr "not a git repo"
  end
endfunction
" }}}
