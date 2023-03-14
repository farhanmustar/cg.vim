" ===========
" MISC CONFIG
" ===========

let g:cg_curl_max_time = get(g:, 'cg_curl_max_time', 120)
let g:cg_curl_cmd = get(g:, 'cg_curl_cmd', 'curl --silent --max-time '.g:cg_curl_max_time)

" ===========
" COMP CONFIG
" ===========

" https://platform.openai.com/docs/api-reference/completions/create
let g:cg_comp_model = get(g:, 'cg_comp_model', 'text-davinci-003')
" let g:cg_comp_model = get(g:, 'cg_comp_model', 'code-davinci-002')  " codex if free for now.
let g:cg_comp_max_token = get(g:, 'cg_comp_max_token', 500)  " limit cost for prompt and reply.
let g:cg_comp_temperature = get(g:, 'cg_comp_temperature', 0)  " 0 - 2 -> higer value less predictable

" ===========
" CHAT CONFIG
" ===========

" TODO: add chat capablility. but only gpt-3.5-turbo support. for now focus on completion.
let g:cg_chat_model = get(g:, 'cg_chat_model', 'gpt-3.5-turbo')
let g:cg_chat_max_token = get(g:, 'cg_chat_max_token', 2000)  " limit cost for request and reply.
let g:cg_chat_temperature = get(g:, 'cg_chat_temperature', 1)  " 0 - 2 -> higer value less predictable
let g:cg_chat_code_promp = get(g:, 'cg_chat_code_promp', 
\   {
\     'role': 'user',
\     'content': 'Reply the following question in markdown format with proper language codeblock for example "```python" for python language sample',
\   }
\ )


" =============
" COMP FUNCTION
" =============

" Main function
function! cg#comp(query) abort
  let g:cg_api_key = get(g:, 'cg_api_key', '')
  if len(g:cg_api_key) == 0
    call s:warn('ChatGPT api key is required to be set to `g:cg_api_key`')
    return
  endif

  let l:cmd = s:get_comp_cmd(g:cg_api_key, a:query)
  call s:send_comp_query(l:cmd, a:query, -1)
endfunction

function! s:get_comp_cmd(api_key, query) abort
  let l:data = {
  \ 'model': g:cg_comp_model,
  \ 'prompt': a:query,
  \ 'max_tokens': g:cg_comp_max_token,
  \ 'temperature': g:cg_comp_temperature,
  \}

  let l:json = json_encode(l:data)

  let l:cmd = [
  \ g:cg_curl_cmd,
  \ '-H',
  \ "'Authorization: Bearer " . a:api_key . "'",
  \ '-H',
	\ "'Content-Type: application/json'",
	\ "https://api.openai.com/v1/completions",
	\ "-d '" . l:json . "'",
  \]

  return join(l:cmd, ' ')
endfunction

function! s:send_comp_query(cmd, query, buf_nr) abort
  echo 'CG querying for response...'
  if has('job')
    let Callback = function('s:comp_job_callback', [a:query, a:buf_nr])
    call job_start(a:cmd, {'close_cb': Callback})
  elseif has('nvim')
    let Callback = function('s:comp_job_callback_nvim', [a:query, a:buf_nr])
    call jobstart(a:cmd, {'on_stdout': Callback, 'stdout_buffered': 1})
  else
    call s:warn('CS.vim require job feature.')
  endif
endfunction

function! s:comp_job_callback(query, buf_nr, channel) abort
  let l:response = []
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    let l:response += [ch_read(a:channel)]
  endwhile
  call s:process_comp_response(l:response, a:query, a:buf_nr)
endfunction

function! s:comp_job_callback_nvim(query, buf_nr, id, data, event) abort
  call s:process_comp_response(a:data, a:query, a:buf_nr)
endfunction

function! s:process_comp_response(response, query, buf_nr) abort
  let l:response = join(a:response, '')
  let l:response = trim(l:response)
  if empty(l:response)
    let l:response = [
    \ a:query,
    \ '',
    \ '---',
    \ '',
    \ 'Fail to get response or response empty.',
    \]
  else
    let l:response = json_decode(l:response)
    let l:response = l:response['choices'][0]['text']
    let l:response = split(l:response, '\n')
    let l:response = [
    \ a:query,
    \ '',
    \ '---',
    \ '',
    \] + l:response
  endif

  let l:cur_winid = win_getid()

  call s:goto_buf(a:buf_nr)
  silent execute 'file' fnameescape('CG '. bufnr())
  call s:fill(l:response)

  call win_gotoid(l:cur_winid)
endfunction

" =============
" CHAT FUNCTION
" =============

function! cg#chat(msg, is_code) abort
  let g:cg_api_key = get(g:, 'cg_api_key', '')
  if len(g:cg_api_key) == 0
    call s:warn('ChatGPT api key is required to be set to `g:cg_api_key`')
    return
  endif

  let l:cmd = s:get_chat_cmd(g:cg_api_key, a:msg, a:is_code)
  call s:send_chat_query(l:cmd, a:msg, -1)
endfunction

function! s:get_chat_cmd(api_key, msg, is_code) abort
  let l:messages = [
  \   {'role': 'user', 'content': a:msg},
  \ ]
  
  if a:is_code
    let l:messages = [g:cg_chat_code_promp] + l:messages
  endif

  let l:data = {
  \ 'model': g:cg_chat_model,
  \ 'max_tokens': g:cg_chat_max_token,
  \ 'temperature': g:cg_chat_temperature,
  \ 'messages': l:messages,
  \}

  let l:json = json_encode(l:data)

  let l:cmd = [
  \ g:cg_curl_cmd,
  \ '-H',
  \ "'Authorization: Bearer " . a:api_key . "'",
  \ '-H',
	\ "'Content-Type: application/json'",
	\ "https://api.openai.com/v1/chat/completions",
	\ "-d '" . l:json . "'",
  \]

  return join(l:cmd, ' ')
endfunction

function! s:send_chat_query(cmd, msg, buf_nr) abort
  echo 'CGC querying for response...'
  if has('job')
    let Callback = function('s:chat_job_callback', [a:msg, a:buf_nr])
    call job_start(a:cmd, {'close_cb': Callback})
  elseif has('nvim')
    let Callback = function('s:chat_job_callback_nvim', [a:msg, a:buf_nr])
    call jobstart(a:cmd, {'on_stdout': Callback, 'stdout_buffered': 1})
  else
    call s:warn('CS.vim require job feature.')
  endif
endfunction

function! s:chat_job_callback(msg, buf_nr, channel) abort
  let l:response = []
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    let l:response += [ch_read(a:channel)]
  endwhile
  call s:process_chat_response(l:response, a:msg, a:buf_nr)
endfunction

function! s:chat_job_callback_nvim(msg, buf_nr, id, data, event) abort
  call s:process_chat_response(a:data, a:msg, a:buf_nr)
endfunction

function! s:process_chat_response(response, msg, buf_nr) abort
  let l:response = join(a:response, '')
  let l:response = trim(l:response)
  if empty(l:response)
    let l:response = [
    \ a:msg,
    \ '',
    \ '---',
    \ '',
    \ 'Fail to get response or response empty.',
    \]
  else
    let l:response = json_decode(l:response)
    let l:response = l:response['choices'][0]['message']['content']
    let l:response = split(l:response, '\n')
    let l:response = [
    \ a:msg,
    \ '',
    \ '---',
    \ '',
    \] + l:response
  endif

  let l:cur_winid = win_getid()

  call s:goto_buf(a:buf_nr)
  silent execute 'file' fnameescape('CGC '. bufnr())
  silent execute 'setfiletype' 'markdown'
  call s:fill(l:response)

  call win_gotoid(l:cur_winid)
endfunction

" ====
" UTIL
" ====

function! s:goto_buf(buf_nr) abort
  let l:buf_nr = bufnr(a:buf_nr)
  if l:buf_nr == -1
    call s:new_buffer()
    return
  elseif l:buf_nr == bufnr()
    return
  endif

  let l:win_id = bufwinid(l:buf_nr)
  if l:win_id == -1
    s:new_window(l:buf_nr)
  else
    call win_gotoid(l:win_id)
  endif
endfunction

function! s:new_buffer() abort
  execute 'below new'
  setlocal buftype=nofile bufhidden=wipe noswapfile nomodeline nobuflisted
endfunction

function! s:new_window(buf_nr) abort
  execute 'below new'
  buffer a:buf_nr
endfunction

function! s:fill(content) abort
  setlocal modifiable
  silent normal! gg"_dG

  call setline('.', a:content)

  setlocal nomodifiable
endfunction

function! s:warn(message) abort
  echohl WarningMsg | echom a:message | echohl None
endfunction
