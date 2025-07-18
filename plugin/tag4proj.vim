" ============================================================================
" Description: autoload tags file for project
" Author: Hongbo Liu <lhbf@qq.com>
" Licence: Vim licence
" Version: 0.10
" ============================================================================

" tags4proj"{{{
let g:tags4proj_cusproj = '.proj'
let g:tags4proj_tagsname = 'tags'
let g:tags4proj_tagsbin = 'ctags'

if !exists('g:tags4proj_tagsopt')
  let g:tags4proj_tagsopt = {
        \ 'opt': ['-R', '--excmd=combine'],
        \ 'inc': ['.'],
        \ 'exclude': ['*.css'],
        \}
endif

let s:vcs_folder = [g:tags4proj_cusproj, '.git', '.hg', '.svn', '.bzr', '_darcs']
let s:vsc_curdir = g:tags4proj_cusproj

function! s:ShowMsgHighlight(msg)
  echohl WarningMsg | echom a:msg | echohl None
endfunction

func! FindVcsRoot() abort
  let s:searchdir = [$ORIG_PWD, expand('%:p:h'), getcwd()]

  let vsc_dir = ''
  for d in s:searchdir
    for vcs in s:vcs_folder
      let vsc_dir = finddir(vcs, d .';')
      if !empty(vsc_dir) | break | endif
    endfor
    if !empty(vsc_dir) | break | endif
  endfor

  let root = empty(vsc_dir) ? '' : fnamemodify(vsc_dir, ':p:h:h')
  let s:vsc_curdir = fnamemodify(vsc_dir, ':p')
  let s:tagpath = s:vsc_curdir . g:tags4proj_tagsname

    return root
endf

function! s:AddTagsOption(tagpath)
  if &tags !~ escape(a:tagpath, '~') && filereadable(a:tagpath)
    let g:tags4proj_tagpath = a:tagpath
    let &tags = a:tagpath . ',' . &tags
  endif
endfunction

function! s:LoadTagFile()
    call FindVcsRoot()
    call s:AddTagsOption(s:tagpath)
endfunction
call <SID>LoadTagFile()

function! s:tagsOptHasKey(key)
  if has_key(g:tags4proj_tagsopt, a:key) && len(g:tags4proj_tagsopt[a:key]) > 0
    return 1
  endif

  return 0
endfunction

function! GenerateTags(tagname, tagSrc, ...) abort
  if empty(FindVcsRoot()) | return -1 | endif

  let tagpath = s:vsc_curdir . a:tagname
  let realTagpath = resolve(tagpath)

  let tagOptStr = ' '
  if s:tagsOptHasKey('opt')
    for item in g:tags4proj_tagsopt.opt
      let tagOptStr .= item . ' '
    endfor
  else
    let tagOptStr .= '-R'
  endif

  if s:tagsOptHasKey('exclude')
    for pattern in g:tags4proj_tagsopt['exclude']
      let tagOptStr .= printf(" --exclude='%s' ", pattern)
    endfor
  endif

  let tagOptStr .= a:tagSrc

  let bgflag = ' &'
  if a:0 > 0 && a:1 == 0 | let bgflag = '' | endif
  let tagcmd = g:tags4proj_tagsbin . ' -f ' . realTagpath . tagOptStr . ' &>/dev/zero ' . bgflag
  let out = system(tagcmd)

  call s:AddTagsOption(tagpath)
endfunction

function! GenerateTagsAll()
  let tagSrc = ''
  let root = FindVcsRoot()
  if empty(root)
    call s:ShowMsgHighlight("Not in any vcs directory !")
    return -1 
  endif

  if s:tagsOptHasKey('inc')
    for item in g:tags4proj_tagsopt.inc
      if !empty(item)
        let tagSrc .= FindVcsRoot() . '/' . item . ' '
      endif
    endfor
  else
    let tagSrc = '.'
  endif

  call GenerateTags(g:tags4proj_tagsname, tagSrc)
endfunction

command! -nargs=0 -bar GenerateProjectTags call GenerateTagsAll()
"}}}
