" LanguageTool: Grammar checker in Vim for English, French, German, etc.
" Maintainer:   Thomas Vigouroux <tomvig38@gmail.com>
" Last Change:  2019 Sep 13
" Version:      1.0
"
" License: {{{1
"
" The VIM LICENSE applies to LanguageTool.nvim plugin
" (see ":help copyright" except use "LanguageTool.nvim" instead of "Vim").
"
" }}} 1

" This function reads the file at file path and returns the preprocessed text
" i.e. with the distinction between markup and real text
" For now it reads the file line by line, apply the rules to be applied and returns the text
" with \n as line separator
function! LanguageTool#preprocess#getProcessedText(lines) "{{{1
    let l:result = []
    for l:line in a:lines
        let l:result = add(l:result, LanguageTool#preprocess#applyRules(l:line))
    endfor

    return join(l:result, ',')
endfunction

" This function applies the rules to the given line, in order
" If none of them applies, the text is considered as only text
" without markup
" For now this is just a function that return the text, it will
" then be used to differentiate markup and text using rules associated with current
" filetype
function! LanguageTool#preprocess#applyRules(line) "{{{1
    if exists('b:languagetool_preprocess_rules')
        for [l:rule, l:output] in b:languagetool_preprocess_rules
            let l:fts = ['tex']
            if (executable('detex') && index(l:fts, &filetype) == -1)
              let l:tex_environs = 'figure,wrapfigure,equation,align'
              if g:tex_flavor == 'latex'
                let l:detex_cmd = 'detex -nlc ' . l:tmpfilename . ' > ' . l:tmpdetex
              else
                let l:detex_cmd = 'detex -nc ' . l:tmpfilename . ' > ' . l:tmpdetex
              endif

              let a:line = system(l:detex_cmd, a:line)
            endif

            let l:matches = matchlist(a:line, l:rule)
            if !empty(l:matches)
                return LanguageTool#preprocess#getOutput(l:matches, l:output) . ',{"text":"\n"}'
            endif
        endfor
    endif
    return LanguageTool#preprocess#getOutput([a:line], '{"text":"{{0}}\n"}')
endfunction

" This function gets output for matches
" The syntax for rules is pretty simple, for a given rule, the output is
" computed by replacing all {{\d+}} groups in a:output by the corresponding group in a:matches
function! LanguageTool#preprocess#getOutput(matches, output) "{{{1
    return substitute(a:output, '{{\(\d\+\)}}',
                \ '\=escape(a:matches[str2nr(submatch(1))], "\"\\\t")', 'g')
endfunction


" This function creates an output string with alternating "markup" and "text"
" Is arguments are not empty, the alternation starts with "markup" else with "text"
function! LanguageTool#preprocess#getOutputAlternate(length, ...) "{{{1
    let l:i = len(a:000) > 0 ? 1 : 0

    let l:result = []

    for l:count in range(a:length)
        call add(l:result, '{"' . (l:i % 2 == 1 ? 'markup' : 'text') . '":"{{' . (l:count + 1) . '}}"}')
        let l:i += 1
    endfor

    return join(l:result, ',')
endfunction
