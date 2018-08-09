" ============================================================================
" Description: autoload tags file for project
" Author: Hongbo Liu <lhbf@qq.com>
" Licence: Vim licence
" Version: 0.10
" ============================================================================

" tags4proj"{{{
let g:tags4proj_cusproj = '.proj'

let g:tags4proj_tagsname = 'tags'
let g:tags4proj_tagsname_delta = 'tags_delta'
let g:tags4proj_tagsbin = 'ctags'

if !exists('g:tags4proj_tagsopt')
	let g:tags4proj_tagsopt = {
				\ 'opt': ['-R'],
				\ 'inc': ['.'],
				\}
endif

let s:vcs_folder = [g:tags4proj_cusproj, '.git', '.hg', '.svn', '.bzr', '_darcs']
let s:vsc_curdir = g:tags4proj_cusproj

function! s:ShowMsgHighlight(msg)
	echohl WarningMsg | echom a:msg | echohl None
endfunction

func! FindVcsRoot() abort
	let s:searchdir = [expand('%:p:h'), getcwd()]

    let vsc_dir = ''
	for d in s:searchdir
		for vcs in s:vcs_folder
			let vsc_dir = finddir(vcs, d .';')
			if !empty(vsc_dir) | break | endif
		endfor
		if !empty(vsc_dir) | break | endif
    endfo

    let root = empty(vsc_dir) ? '' : fnamemodify(vsc_dir, ':p:h:h')
	let s:vsc_curdir = fnamemodify(vsc_dir, ':p')
	let s:tagpath = s:vsc_curdir . g:tags4proj_tagsname

    return root
endf

function! s:AddTagsOption(tagpath)
	if &tags !~ a:tagpath
		let &tags = a:tagpath . ',' . &tags
	endif
endfunction

function! GenerateTags(tagname, tagSrc, ...) abort
	if empty(FindVcsRoot()) | return -1 | endif

	let tagpath = s:vsc_curdir . a:tagname
	let realTagpath = resolve(tagpath)

	" if filereadable(tagpath)
        " if delete(tagpath)
			" call s:ShowMsgHighlight("Tags file " . tagpath . "exists, but can't be deleted !")
            " return -2
        " endif
	" endif

	let tagOptStr = ' '
	for item in g:tags4proj_tagsopt.opt
		let tagOptStr .= item . ' '
	endfor
	let tagOptStr .= a:tagSrc

	let bgflag = ' &'
	if a:0 > 0 && a:1 == 0 | let bgflag = '' | endif
	let tagcmd = g:tags4proj_tagsbin . ' -f' . realTagpath . tagOptStr . ' &>/dev/zero ' . bgflag
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
	for item in g:tags4proj_tagsopt.inc
		if !empty(item)
			let tagSrc .= FindVcsRoot() . '/' . item . ' '
		endif
	endfor

	call GenerateTags(g:tags4proj_tagsname, tagSrc)
endfunction

function! GenerateTagsDelta()
	call GenerateTags(g:tags4proj_tagsname_delta, expand('%:p'), 0)
endfunction

function! s:MakeBufferMap()
	" nnoremap <nowait> <buffer> <silent> <C-]> :call LoadOrCreate(expand('<cword>'), 'tag ')<cr>
	" vnoremap <nowait> <buffer> <silent> <C-]> "vy:call LoadOrCreate('<c-r>v', 'tag /')<cr>
endfunction

function! LoadOrCreate(tag, cmd)
	if empty(taglist('^' . a:tag . '$'))
		call GenerateTagsDelta()
	endif
	execute(a:cmd . a:tag)
endfunction

function! JumpToDefinition(tag)
	let result = taglist('^' . a:tag . '$')

	if len(result) <= 1
		execute('tag ' . a:tag)
		return 0
	endif

	let index = 1
	for t in result
		if t['kind'] == 'function'
			execute('e ' . t['filename'])
			let t['cmd'] = substitute(t['cmd'], '\/', '\/\\M', '')
			execute(t['cmd'])
			" execute(index . 'tag ' . a:tag)
			return 0
		endif
		let index += 1
	endfor

	execute('tag ' . a:tag)
endfunction

command! -nargs=0 -bar GenerateProjectTags call GenerateTagsAll()
"}}}
