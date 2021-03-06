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
    return -1
  endif
endfunction

function! git#FindBufferNameRelativeToGitRepo()
  let git_repo_root = git#FindGitRepoRoot()

  if git_repo_root !=# -1
    let full_path_of_buffer = fnamemodify(bufname("%"), ":p")
    return fnamemodify(full_path_of_buffer, ':s?' . git#FindGitRepoRoot() . '/??') 
  else
    echoerr "not a git repo"
    return -1
  endif
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

function! git#GitCommitAndPushCommitMsgFile(type)
  if b:git_commit_file_written ==# 1
    let git_repo_root = git#FindGitRepoRoot()

    if git_repo_root !=# -1
      if a:type ==# 'file'
        let git_system_string = "cd " . git_repo_root . " && git add " . b:file_to_commit . " && git commit -F " . git#CommitMsgFilename() . " && git push"
      elseif a:type ==# 'all'
        let git_system_string = "cd " . git_repo_root . " && git add -A && git commit -F " . git#CommitMsgFilename() . " && git push"
      endif

      echom "[git.vim] executing: " . git_system_string . "..."

      let result = system(git_system_string)
      
      for line in split(result, '\v\n')
        echom "[git.vim] " . line
      endfor

      call feedkeys("\<cr>")
    else
      echoerr "not a git repo"
      return -1
    endif
  endif
endfunction
" }}}
" public functions {{{
function! git#GitDiff(type)
  write

  let git_repo_root = git#FindGitRepoRoot()

  if git_repo_root !=# -1
    if a:type ==# 'file' 
      let git_system_string = "cd " . git_repo_root . " && git diff " . git#FindBufferNameRelativeToGitRepo()
    elseif a:type ==# 'all'
      let git_system_string = "cd " . git_repo_root . " && git diff"
    endif

    let git_diff_result = system(git_system_string)

    if git_diff_result =~ '\v^Not a git repository'
      echoerr "not a git repo"
    else
      call git#OpenOrFocusBuffer('__Git_Diff__')

      normal! ggdG
      setlocal filetype=gitdiff
      setlocal buftype=nofile

      call append(0, split(git_diff_result, '\v\n'))

      normal! gg
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

function! git#GitStatus()
  write

  let git_repo_root = git#FindGitRepoRoot()

  if git_repo_root !=# -1
    let git_system_string = "cd " . git_repo_root . " && git status"

    let git_status_result = system(git_system_string)

    if git_status_result =~ '\v^Not a git repository'
      echoerr "not a git repo"
    else
      call git#OpenOrFocusBuffer('__Git_Status__')

      normal! ggdG
      setlocal filetype=gitstatus
      setlocal buftype=nofile

      call append(0, split(git_status_result, '\v\n'))

      normal! gg
    end
  else
    echoerr "not a git repo"
  end
endfunction

function! git#GitCommit(type)
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

      if a:type ==# 'file'
        autocmd BufWinLeave <buffer> call git#GitCommitAndPushCommitMsgFile('file')
      elseif a:type ==# 'all'
        autocmd BufWinLeave <buffer> call git#GitCommitAndPushCommitMsgFile('all')
      endif
    augroup END

    normal! ggdG
    setlocal filetype=gitcommit

    call feedkeys('i')
  else
    echoerr "not a git repo"
  end
endfunction
" }}}
