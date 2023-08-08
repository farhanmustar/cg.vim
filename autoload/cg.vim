" ===========
" MISC CONFIG
" ===========

let g:cg_curl_max_time = get(g:, 'cg_curl_max_time', 120)
let g:cg_curl_cmd = get(g:, 'cg_curl_cmd', 'curl --silent --max-time '.g:cg_curl_max_time)

" ===========
" COMP CONFIG
" ===========

let g:cg_comp_model = get(g:, 'cg_comp_model', 'text-davinci-003')
" let g:cg_comp_model = get(g:, 'cg_comp_model', 'code-davinci-002')
let g:cg_comp_max_token = get(g:, 'cg_comp_max_token', 500)  " limit cost for prompt and reply.
let g:cg_comp_temperature = get(g:, 'cg_comp_temperature', 0)  " 0 - 2 -> higer value less predictable

" ===========
" CHAT CONFIG
" ===========

let g:cg_chat_model = get(g:, 'cg_chat_model', 'gpt-3.5-turbo')
let g:cg_chat_max_token = get(g:, 'cg_chat_max_token', 2000)  " limit cost for request and reply.
let g:cg_chat_temperature = get(g:, 'cg_chat_temperature', 1)  " 0 - 2 -> higer value less predictable
let g:cg_chat_history_count = get(g:, 'cg_chat_history_count', 3)  " limit prev history count to send
let g:cg_chat_code_promp = get(g:, 'cg_chat_code_promp', 
\   {
\     'role': 'user',
\     'content': 'Reply the following question in markdown format with proper language codeblock for example "```python" for python language sample',
\   }
\ )

let g:cg_welcome_txt = 'Shortcut:' .
      \ "\n    * cc          - create new reply" .
      \ "\n    * <           - browse previous msgs" .
      \ "\n    * >           - browse next msgs" .
      \ "\n    * <leader>af  - fix reply newline formatting error"

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
	\ "--data-binary @-",
  \]

  return [join(l:cmd, ' '), l:json]
endfunction

function! s:send_comp_query(cmd, query, buf_nr) abort
  echo 'CG querying for response...'
  if has('job')
    let Callback = function('s:comp_job_callback', [a:query, a:buf_nr])
    let job = job_start(a:cmd[0], {'close_cb': Callback})
    let channel = job_getchannel(job)
    call ch_sendraw(channel, a:cmd[1])
    call ch_close_in(channel)
  elseif has('nvim')
    let Callback = function('s:comp_job_callback_nvim', [a:query, a:buf_nr])
    let jobid = jobstart(a:cmd[0], {'on_stdout': Callback, 'stdout_buffered': 1})
    call chansend(jobid, a:cmd[1])
    call chanclose(jobid, 'stdin')
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
  echo ''
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
    try
      let l:response = json_decode(l:response)
      let l:response = l:response['choices'][0]['text']
      let l:response = split(l:response, '\n')
      let l:response = [
      \ a:query,
      \ '',
      \ '---',
      \ '',
      \] + l:response
    catch
      echom a:response
      call s:warn('Fail to process response.')
      return
    endtry
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

function! cg#chat(msg, is_code, buf_nr) abort
  let g:cg_api_key = get(g:, 'cg_api_key', '')
  if len(g:cg_api_key) == 0
    call s:warn('ChatGPT api key is required to be set to `g:cg_api_key`')
    return
  endif

  if len(a:msg) == 1 && empty(a:msg[0])
    call s:goto_buf(-1)
    call s:fill(split(g:cg_welcome_txt, '\n'))
    call s:empty_post_chat(a:is_code)
    return
  endif

  let l:cmd = s:get_chat_cmd(g:cg_api_key, a:msg, a:is_code, a:buf_nr)
  call s:send_chat_query(l:cmd, a:msg, a:is_code, a:buf_nr)
endfunction

function! cg#chat_commit() abort
  if !exists('b:cg_chat_buf')
    return
  endif
  let l:buf_nr = bufnr()
  let l:is_code = get(b:, 'cg_is_code', 0)

  let l:commit_buf_nr = (l:is_code ? 'CGCode' : 'CGC') . ' Commit ' . l:buf_nr
  call s:goto_buf(l:commit_buf_nr)

  if exists('b:cg_chat_commit_buf')
    return
  endif

  silent execute 'file' fnameescape(l:commit_buf_nr)
  silent execute 'setfiletype' 'markdown'

  let b:cg_is_code = l:is_code
  let b:cg_buf_nr = l:buf_nr
  let b:cg_chat_commit_buf = 1

  augroup CGCOMMIT
       autocmd! * <buffer>
       autocmd BufUnload <buffer> call <SID>commit_buf_submit()
  augroup END
endfunction

function! s:commit_buf_submit() abort
  if !exists('b:cg_chat_commit_buf')
    return
  endif
  let l:commit_msg = getbufline('%', 1, '$')
  if empty(trim(join(l:commit_msg, '')))
    return
  end

  call cg#chat(l:commit_msg, b:cg_is_code, b:cg_buf_nr)
endfunction

function! s:get_chat_cmd(api_key, msg, is_code, buf_nr) abort
  let l:messages = s:get_chat_prev_msg(a:buf_nr) + [
  \   {'role': 'user', 'content': join(a:msg, '\n')},
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
	\ "--data-binary @-",
  \]

  return [join(l:cmd, ' '), l:json]
endfunction

function! s:get_chat_prev_msg(buf_nr) abort
  let l:messages = []
  let l:buf_nr = bufnr(a:buf_nr)
  if l:buf_nr == -1
    return l:messages
  endif

  let l:prev_messages = getbufvar(l:buf_nr, 'cg_messages', [])

  for data in l:prev_messages
    if empty(data['response'])
      continue
    endif
    call add(l:messages, {'role': 'user', 'content': join(data['msg'], '\n')})
    call add(l:messages, {'role': 'assistant', 'content': join(data['response'], '\n')})
  endfor

  let l:messages = len(l:messages) > (g:cg_chat_history_count * 2) ?
    \ l:messages[-(g:cg_chat_history_count * 2):] : l:messages

  return l:messages
endfunction

function! s:send_chat_query(cmd, msg, is_code, buf_nr) abort
  echo 'CGC querying for response...'
  if has('job')
    let Callback = function('s:chat_job_callback', [a:msg, a:is_code, a:buf_nr])
    let job = job_start(a:cmd[0], {'close_cb': Callback})
    let channel = job_getchannel(job)
    call ch_sendraw(channel, a:cmd[1])
    call ch_close_in(channel)
  elseif has('nvim')
    let Callback = function('s:chat_job_callback_nvim', [a:msg, a:is_code, a:buf_nr])
    let jobid = jobstart(a:cmd[0], {'on_stdout': Callback, 'stdout_buffered': 1})
    call chansend(jobid, a:cmd[1])
    call chanclose(jobid, 'stdin')
  else
    call s:warn('CS.vim require job feature.')
  endif
endfunction

function! s:chat_job_callback(msg, is_code, buf_nr, channel) abort
  let l:response = []
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    let l:response += [ch_read(a:channel)]
  endwhile
  call s:process_chat_response(l:response, a:msg, a:is_code, a:buf_nr)
endfunction

function! s:chat_job_callback_nvim(msg, is_code, buf_nr, id, data, event) abort
  call s:process_chat_response(a:data, a:msg, a:is_code, a:buf_nr)
endfunction

function! s:process_chat_response(response, msg, is_code, buf_nr) abort
  echo ''
  let l:response = join(a:response, '')
  let l:response = trim(l:response)
  if empty(l:response)
    let l:response = []
  else
    try
      let l:response = json_decode(l:response)
      let l:response = l:response['choices'][0]['message']['content']
      let l:response = split(l:response, '\n')
    catch
      echom a:response
      call s:warn('Fail to process response.')
      return
    endtry
  endif

  let l:content = s:gen_chat_content(a:msg, l:response)

  let l:cur_winid = win_getid()

  call s:goto_buf(a:buf_nr)
  call s:fill(l:content)
  call s:post_chat(a:msg, l:response, a:is_code)

  call win_gotoid(l:cur_winid)
endfunction

function! s:gen_chat_content(msg, response) abort
  return a:msg + [
  \ '',
  \ '---',
  \ '',
  \] + (empty(a:response) ? ['Fail to get response or response empty.'] : a:response)
endfunction

function! s:post_chat(msg, response, is_code) abort
  let b:cg_messages = get(b:, 'cg_messages', [])
  call add(b:cg_messages, {
  \   'msg': a:msg,
  \   'response': a:response
  \ })
  let b:cg_chat_cur_msg = len(b:cg_messages) - 1

  if exists('b:cg_chat_buf')
    return
  endif

  call s:set_chat_maps()
  silent execute 'file' fnameescape((a:is_code ? 'CGCode ' : 'CGC '). bufnr())
  silent execute 'setfiletype' 'markdown'

  let b:cg_is_code = a:is_code ? 1 : 0
  let b:cg_chat_buf = 1
endfunction

function! s:empty_post_chat(is_code) abort
  let b:cg_messages = get(b:, 'cg_messages', [])
  let b:cg_chat_cur_msg = len(b:cg_messages) - 1

  if exists('b:cg_chat_buf')
    return
  endif

  call s:set_chat_maps()
  silent execute 'file' fnameescape((a:is_code ? 'CGCode ' : 'CGC '). bufnr())
  silent execute 'setfiletype' 'markdown'

  let b:cg_is_code = a:is_code ? 1 : 0
  let b:cg_chat_buf = 1
endfunction

function! s:set_chat_maps() abort
  nnoremap <silent> <buffer> > :call cg#chat_next()<cr>
  nnoremap <silent> <buffer> < :call cg#chat_prev()<cr>
  nnoremap <silent> <buffer> <leader>af :call cg#chat_format()<cr>
  nnoremap <silent> <buffer> cc :call cg#chat_commit()<cr>
endfunction

function! cg#chat_next() abort
  if !exists('b:cg_chat_buf')
    return
  endif

  let l:cur_idx = b:cg_chat_cur_msg + 1

  if l:cur_idx >= len(b:cg_messages)
    echo 'CGC no next message'
    return
  endif

  let b:cg_chat_cur_msg = l:cur_idx

  let l:data = b:cg_messages[l:cur_idx]
  let l:msg = l:data['msg']
  let l:response = l:data['response']

  let win_state = winsaveview()

  let l:content = s:gen_chat_content(l:msg, l:response)
  call s:fill(l:content)

  call winrestview(win_state)
endfunction

function! cg#chat_prev() abort
  if !exists('b:cg_chat_buf')
    return
  endif

  let l:cur_idx = b:cg_chat_cur_msg - 1

  if l:cur_idx < 0
    echo 'CGC no prev message'
    return
  endif

  let b:cg_chat_cur_msg = l:cur_idx

  let l:data = b:cg_messages[l:cur_idx]
  let l:msg = l:data['msg']
  let l:response = l:data['response']

  let win_state = winsaveview()

  let l:content = s:gen_chat_content(l:msg, l:response)
  call s:fill(l:content)

  call winrestview(win_state)
endfunction

function! cg#chat_format() abort
  " fix sometimes ai reply with literal \n
  if !exists('b:cg_chat_buf')
    return
  endif

  let l:cur_idx = b:cg_chat_cur_msg

  let l:data = b:cg_messages[l:cur_idx]
  let l:msg = l:data['msg']
  let l:response = split(join(l:data['response'], '\\n'), '\\n')

  let win_state = winsaveview()

  let l:content = s:gen_chat_content(l:msg, l:response)
  call s:fill(l:content)

  call winrestview(win_state)
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
