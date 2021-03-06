" Author:  Eric Van Dewoestine
"
" Description: {{{
"   see http://eclim.sourceforge.net/vim/javascript/validate.html
"
" License:
"
" Copyright (C) 2005 - 2009  Eric Van Dewoestine
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
"
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU General Public License for more details.
"
" You should have received a copy of the GNU General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"
" }}}

" Global Variables {{{
  if !exists('g:EclimJavascriptLintConf')
    let g:EclimJavascriptLintConf = '~/.jslrc'
  endif
" }}}

" Script Variables {{{
  let s:warnings = '\(' . join([
      \ 'imported but unused',
    \ ], '\|') . '\)'
" }}}

" Validate(on_save) {{{
" Validates the current file.
function! eclim#javascript#validate#Validate(on_save)
  if eclim#util#WillWrittenBufferClose()
    return
  endif

  "if !eclim#project#util#IsCurrentFileInProject(!a:on_save)
  "  return
  "endif

  let result = ''

  if !executable('jsl')
    if !exists('g:eclim_javascript_jsl_warn')
      call eclim#util#EchoWarning("Unable to find 'jsl' command.")
      let g:eclim_javascript_jsl_warn = 1
    endif
  else
    let command = 'jsl -process "' . expand('%:p') . '"'
    let conf = expand(g:EclimJavascriptLintConf)
    if filereadable(conf)
      let command .= ' -conf "' . conf . '"'
    endif
    let result = eclim#util#System(command)
    if v:shell_error == 2 "|| v:shell_error == 4
      call eclim#util#EchoError('Error running command: ' . command)
      return
    endif
  endif

  if result =~ ':'
    let results = split(result, '\n')
    let errors = []
    for error in results
      if error =~ '.\{-}(\d\+): .\{-}: .\{-}'
        let file = substitute(error, '\(.\{-}\)([0-9]\+):.*', '\1', '')
        let line = substitute(error, '.\{-}(\([0-9]\+\)):.*', '\1', '')
        let message = substitute(error, '.\{-}([0-9]\+):.\{-}: \(.*\)', '\1', '')
        let dict = {
            \ 'filename': eclim#util#Simplify(file),
            \ 'lnum': line,
            \ 'text': message,
            \ 'type': error =~ ': \(lint \)\?warning:' ? 'w' : 'e',
          \ }

        call add(errors, dict)
      endif
    endfor

    call eclim#util#SetLocationList(errors)
  else
    call eclim#util#ClearLocationList()
  endif
endfunction " }}}

" vim:ft=vim:fdm=marker
