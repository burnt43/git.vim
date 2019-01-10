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

function! git#GitDiff()
  write

  let current_directory                      = fnamemodify(bufname("%"), ":p:h")
  let closest_git_repo_directory             = git#FindGitRepo()
  let full_path_of_buffer                    = fnamemodify(bufname("%"), ":p")
  let buffer_path_relative_to_repo_directory = fnamemodify(full_path_of_buffer, ':s?' . closest_git_repo_directory . '/??') 

  if closest_git_repo_directory !=# -1
    let git_diff_result = system("cd " . closest_git_repo_directory . "&& git diff " . buffer_path_relative_to_repo_directory)

    if git_diff_result =~ '\v^Not a git repository'
      echoerr "not a git repo"
    else
      let git_diff_buffer = bufwinnr('__Git_Diff__')

      if git_diff_buffer >= 0
        execute git_diff_buffer . "wincmd w"
      else
        split __Git_Diff__
      endif

      normal! ggdG
      setlocal filetype=gitdiff
      setlocal buftype=nofile

      call append(0, split(git_diff_result, '\v\n'))
    end

    execute "silent !cd " . current_directory
    redraw!
  else
    echoerr "not a git repo"
  end
endfunction
