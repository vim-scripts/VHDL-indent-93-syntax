" VHDL indent file ('93 syntax)
" Language:    VHDL
" Maintainer:  Gerald Lai <laigera+vim?gmail.com>
" Credits:     N. J. Heo & Janez Stangelj
" Version:     1.0
" Last Change: 2006 Jan 24

" only load this indent file when no other was loaded
if exists("b:did_indent")
  finish
endif
let b:did_indent = 1

" setup indent options for local VHDL buffer
setlocal indentexpr=GetVHDLindent()
setlocal indentkeys=!^F,o,O,e,0(,0)
setlocal indentkeys+==~if,=~then,=~elsif,=~else
setlocal indentkeys+==~begin,=~is,=~select,=~--

" move around
" keywords: "architecture", "block", "configuration", "component", "entity", "function", "package", "procedure", "process", "record", "units"
let b:vhdl_explore = '\%(architecture\|block\|configuration\|component\|entity\|function\|package\|procedure\|process\|record\|units\)'
nnoremap <silent><buffer>[[ :cal search('\%(\<end\s\+\)\@<!\<'.b:vhdl_explore.'\>\c','bW')<CR>
nnoremap <silent><buffer>]] :cal search('\%(\<end\s\+\)\@<!\<'.b:vhdl_explore.'\>\c','W')<CR>
nnoremap <silent><buffer>[] :cal search('\<end\s\+'.b:vhdl_explore.'\>\c','bW')<CR>
nnoremap <silent><buffer>][ :cal search('\<end\s\+'.b:vhdl_explore.'\>\c','W')<CR>

" constants
" not a comment
let s:NC = '\%(--.*\)\@<!'
" end of string
let s:ES = '\s*\%(--.*\)\=$'
" no "end" keyword in front
let s:NE = '\%(\<end\s\+\)\@<!'

" for matchit plugin
if exists("loaded_matchit")
  let b:match_ignorecase = 1
  let b:match_words =
    \ s:NE.'\<if\>:\<elsif\>:\<else\>:\<end\s\+if\>,'.
    \ s:NE.'\<case\>:\<when\>:\<end\s\+case\>,'.
    \ s:NE.'\<loop\>:\<end\s\+loop\>,'.
    \ s:NE.'\<for\>:\<end\s\+for\>,'.
    \ s:NE.'\<generate\>:\<end\s\+generate\>,'.
    \ s:NE.'\<record\>:\<end\s\+record\>,'.
    \ s:NE.'\<units\>:\<end\s\+units\>,'.
    \ s:NE.'\<process\>:\<end\s\+process\>,'.
    \ s:NE.'\<block\>:\<end\s\+block\>,'.
    \ s:NE.'\<function\>:\<end\s\+function\>,'.
    \ s:NE.'\<entity\>:\<end\s\+entity\>,'.
    \ s:NE.'\<component\>:\<end\s\+component\>,'.
    \ s:NE.'\<architecture\>:\<end\s\+architecture\>,'.
    \ s:NE.'\<package\>:\<end\s\+package\>,'.
    \ s:NE.'\<procedure\>:\<end\s\+procedure\>,'.
    \ s:NE.'\<configuration\>:\<end\s\+configuration\>'
endif

" only define indent function once
if exists("*GetVHDLindent")
  finish
endif

function GetVHDLindent()
  " store current line & string
  let curn = v:lnum
  let curs = getline(curn)

  " indent:   previous line's comment position
  " keyword:  "--"
  " where:    start of current line
  if curs =~ '^\s*--'
    let prevn = curn - 1
    let prevs = getline(prevn)
    return stridx(prevs, '--')
  endif

  " find prevnonblank line that is not a comment
  let prevn = prevnonblank(curn - 1)
  let prevs = getline(prevn)
  while prevn > 0 && prevs =~ '^\s*--'
    let prevn = prevnonblank(prevn - 1)
    let prevs = getline(prevn)
  endwhile

  " default indent starts as prevnonblank non-comment line's indent
  let ind = prevn > 0 ? indent(prevn) : 0

  " ****************************************************************************************
  " indent:   align generic variables & port names
  " keywords: "generic", "port/map" + "("
  " where:    anywhere in previous line
  if prevs =~? s:NC.'\<\%(port\%(\s\+map\)\=\|generic\)\s*('
    let m = matchend(prevs, '(\s*\ze\w')
    if m != -1
      return m
    else
      return stridx(prevs, '(') + &sw
    endif
  endif

  " indent:   align conditional/select statement
  " keywords: "<=" without ";" ending
  " where:    anywhere in previous line
  if prevs =~ s:NC.'<=[^;]*'.s:ES
    return matchend(prevs, '<=\s*\ze.')
  endif

  " indent:   +sw
  " keyword:  "("
  " where:    end of previous line
  if prevs =~ s:NC.'('.s:ES
    return ind + &sw
  endif

  " indent:   backtrace prevnonblank non-comment lines for next smaller or equal size indent
  " keyword:  ")"
  " where:    start of previous line
  " keyword:  without "<=" & ending with ";"
  " where:    anywhere in previous line
  " keywords: "end" + "record", "units"
  " where:    start of previous line
  " _note_:   indent allowed to leave this filter
  let m = 0
  if prevs =~ '^\s*)'
    let m = 1
  elseif prevs =~? s:NC.'\%(<=.*\)\@<!;'
    let m = 2
  elseif prevs =~? '^\s*end\s\+\%(record\|units\)\>'
    let m = 3
  endif

  if m > 0
    let pn = prevnonblank(prevn - 1)
    let ps = getline(pn)
    while pn > 0
      let t = indent(pn)
      if ps !~ '^\s*--' && t < ind
        " make sure previous non-comment line has "<=" without ";" ending 
        if m == 2 && ps !~ s:NC.'<=[^;]*'.s:ES
          break
        endif
        let ind = t
        if m > 1
          " find following previous non-comment line
          let ppn = prevnonblank(pn - 1)
          let pps = getline(ppn)
          while ppn > 0 && pps =~ '^\s*--'
            let ppn = prevnonblank(ppn - 1)
            let pps = getline(ppn)
          endwhile
          " indent:   follow
          " keyword:  "select"
          " where:    end of following previous non-comment line
          " keyword:  "type"
          " where:    start of following previous non-comment line
          if m == 2
            let s1 = s:NC.'\<select'.s:ES
            if ps !~? s1 && pps =~? s1
              let ind = indent(ppn)
            endif
          elseif m == 3
            let s1 = '^\s*type\>'
            if ps !~? s1 && pps =~? s1
              let ind = indent(ppn)
            endif
          endif
        endif
        break
      endif
      let pn = prevnonblank(pn - 1)
      let ps = getline(pn)
    endwhile
  endif

  " indent:   follow indent of previous opening statement, otherwise -sw
  " keyword:  "begin"
  " where:    anywhere in current line
  if curs =~? s:NC.'\<begin\>'
    let ind = ind - &sw
    " find previous opening statement of
    " keywords: "architecture", "block", "entity", "function", "generate", "procedure", "process"
    let s2 = s:NC.s:NE.'\<\%(architecture\|block\|entity\|function\|generate\|procedure\|process\)\>'
    if curs !~? s2.'.*\<begin\>.*'.s:ES && prevs =~? s2
      let ind = ind + &sw
    endif
    return ind
  endif

  " indent:   +sw if previous line is previous opening statement
  " keywords: "record", "units"
  " where:    anywhere in current line
  if curs =~? s:NC.s:NE.'\<\%(record\|units\)\>'
    " find previous opening statement of
    " keyword: "type"
    let s3 = s:NC.s:NE.'\<type\>'
    if curs !~? s3.'.*\<\%(record\|units\)\>.*'.s:ES && prevs =~? s3
      let ind = ind + &sw
    endif
    return ind
  endif

  " ****************************************************************************************
  " indent:   0
  " keywords: "architecture", "configuration", "entity", "library", "package"
  " where:    start of current line
  if curs =~? '^\s*\%(architecture\|configuration\|entity\|library\|package\)\>'
    return 0
  endif

  " indent:   follow indent of previous opening statement
  " keyword:  "is"
  " where:    start of current line
  " find previous opening statement of
  " keywords: "architecture", "block", "configuration", "entity", "function", "package", "procedure", "process", "type"
  if curs =~? '^\s*\<is\>' && prevs =~? s:NC.s:NE.'\<\%(architecture\|block\|configuration\|entity\|function\|package\|procedure\|process\|type\)\>'
    return indent(prevn)
  endif

  " indent:   follow indent of previous opening statement
  " keyword:  "then"
  " where:    start of current line
  " find previous opening statement of
  " keywords: "elsif", "if"
  if curs =~? '^\s*\<then\>' && (prevs =~? s:NC.'\<elsif\>' || prevs =~? s:NC.s:NE.'\<if\>')
    return indent(prevn)
  endif

  " indent:   follow indent of previous opening statement
  " keyword:  "generate"
  " where:    start of current line
  " find previous opening statement of
  " keywords: "for", "if"
  if curs =~? '^\s*\<generate\>' && (prevs =~? s:NC.'\<for\>' || prevs =~? s:NC.s:NE.'\<if\>')
    return indent(prevn)
  endif

  " indent:   +sw
  " keywords: "block", "for", "loop", "process", "record", "units"
  " removed:  "case", "if"
  " where:    anywhere in previous line
  if prevs =~? s:NC.s:NE.'\<\%(block\|for\|loop\|process\|record\|units\)\>'
    return ind + &sw
  endif

  " indent:   +sw
  " keywords: "begin"
  " removed:  "elsif", "while"
  " where:    anywhere in previous line
  if prevs =~? s:NC.'\<begin\>'
    return ind + &sw
  endif

  " indent:   +sw
  " keywords: "architecture", "component", "configuration", "entity", "package"
  " removed:  "package", "when", "with"
  " where:    start of previous line
  if prevs =~? '^\s*\%(architecture\|component\|configuration\|entity\|package\)\>'
    return ind + &sw
  endif

  " indent:   +sw
  " keyword:  "generate", "is", "select", "=>"
  " where:    end of previous line
  if prevs =~? s:NC.'\<\%(generate\|is\|select\)'.s:ES || prevs =~? s:NC.'=>'.s:ES
    return ind + &sw
  endif

  " indent:   +sw
  " keyword:  "else", "then"
  " where:    end of previous line
  " _note_:   indent allowed to leave this filter
  if prevs =~? s:NC.'\<\%(else\|then\)'.s:ES
    let ind = ind + &sw
  endif

  " ****************************************************************************************
  " indent:   -sw
  " keywords: "else", "elsif", "when"
  " where:    start of current line
  if curs =~? '^\s*\%(else\|elsif\|when\)\>'
    return ind - &sw
  endif

  " indent:   -sw
  " keywords: "end" + "block", "component", "for", "function", "generate", "if", "loop", "procedure", "process", "record", "units"
  " where:    start of current line
  " keyword:  ")"
  " where:    start of current line
  if curs =~? '^\s*end\s\+\%(block\|component\|for\|function\|generate\|if\|loop\|procedure\|process\|record\|units\)\>' || curs =~ '^\s*)'
    return ind - &sw
  endif

  " indent:   -2sw
  " keyword:  "end" + "case"
  " where:    start of current line
  if curs =~? '^\s*end\s\+case\>'
    return ind - 2 * &sw
  endif

  " indent:   0
  " keywords: "end" + "architecture", "configuration", "entity", "package", identifier
  " where:    start of current line
  if curs =~? '^\s*end\s\+\%(architecture\|configuration\|entity\|package\|\w*\)\>'
    return 0
  endif

  " return leftover filtered indent
  return ind
endfunction
