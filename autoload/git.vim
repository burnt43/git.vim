" private functions {{{
function! git#FindGitRepoRoot()
  if exists("b:git_repo_root")
    return b:git_repo_root
  else
    let current_directory = fnamemodify(bufname("%"), ":p:h")
    
    while current_directory !=# '/'
      if !empty(glob(current_directory . '/' . '.git'))
        let b:git_repo_root = current_directory
        return b:git_repo_root
      else
        let current_directory = fnamemodify(current_directory, ":h")
      endif
    endwhile

    return -1
  endif
endfunction

function! git#CommitMsgFilename()
  let git_repo_root = git#FindGitRepoRoot()

  if git_repo_root !=# -1
    return git_repo_root . '/.git/COMMIT_EDITMSG'
  else
    echoerr "not a git repo"
  endif
endfunction

function! git#FindBufferNameRelativeToGitRepo()
  let full_path_of_buffer = fnamemodify(bufname("%"), ":p")

  return fnamemodify(full_path_of_buffer, ':s?' . git#FindGitRepoRoot() . '/??') 
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

function! git#GitCommitAndPushCommitMsgFile()
  let git_repo_root = git#FindGitRepoRoot()
  echom("commiting...")

  if git_repo_root !=# -1
    echom("really commiting...")
    let result = system("cd " . git_repo_root . " && git add " . b:file_to_commit . " && git commit -F " . git#CommitMsgFilename() . " && git push")
    echom(result)
  else
    echoerr "not a git repo"
  endif
endfunction
" }}}
" public functions {{{
function! git#GitDiff()
  write

  let git_repo_root = git#FindGitRepoRoot()

  if git_repo_root !=# -1
    let git_diff_result = system("cd " . git_repo_root . "&& git diff " . git#FindBufferNameRelativeToGitRepo())

    if git_diff_result =~ '\v^Not a git repository'
      echoerr "not a git repo"
    else
      call git#OpenOrFocusBuffer('__Git_Diff__')

      normal! ggdGi
      setlocal filetype=gitdiff
      setlocal buftype=nofile

      call append(0, split(git_diff_result, '\v\n'))
    end
  else
    echoerr "not a git repo"
  end
endfunction

function! git#GitRefresh()
  let git_repo_root = git#FindGitRepoRoot()

  if git_repo_root !=# -1
    execute "silent !cd " . git_repo_root . " && git checkout " . git#FindBufferNameRelativeToGitRepo()
    edit
    redraw!
  else
    echoerr "not a git repo"
  endif
endfunction

function! git#GitCommit()
  write

  let git_repo_root                    = git#FindGitRepoRoot()
  let commit_msg_filename              = git_repo_root . '/.git/COMMIT_EDITMSG'
  let buffer_name_relative_to_git_repo = git#FindBufferNameRelativeToGitRepo()

  if git_repo_root !=# -1
    let open_buffer_result = git#OpenOrFocusBuffer(commit_msg_filename)

    if open_buffer_result
      let b:git_commit_file_written = 0
    endif
    let b:file_to_commit = buffer_name_relative_to_git_repo

    augroup git_commit
      autocmd!
      autocmd BufWritePost <buffer> let b:git_commit_file_written=1
      autocmd BufWinLeave <buffer> call git#GitCommitAndPushCommitMsgFile()
    augroup END

    normal! ggdG
    setlocal filetype=gitcommit
  else
    echoerr "not a git repo"
  end
endfunction
" }}}
