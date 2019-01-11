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
    return 0
  else
    execute "split " . a:buffer_name
    return 1
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

  let git_repo_directory       = git#FindGitRepo()
  let commit_edit_msg_filename = git_repo_directory . '/.git/COMMIT_EDITMSG'

  if git_repo_directory !=# -1
    let open_buffer_result = git#OpenOrFocusBuffer(commit_edit_msg_filename)

    if open_buffer_result
      echom("written = 0")
      let b:git_commit_file_written = 0
    endif

    augroup git_commit
      autocmd!
      autocmd BufWritePost <buffer> echom("written=1") | let b:git_commit_file_written=1
      autocmd BufWinLeave <buffer> execute "echom('this is the part where we commit and push')"
    augroup END

    normal! ggdG
    setlocal filetype=gitcommit
  else
    echoerr "not a git repo"
  end
endfunction
" }}}
