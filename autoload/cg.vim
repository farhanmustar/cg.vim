let g:cg_curl_max_time = get(g:, 'cg_curl_max_time', 30)
let g:cg_curl_cmd = get(g:, 'cg_curl_cmd', 'curl --silent --max-time '.g:cg_curl_max_time)

" Main function

function! cg#query(query) abort
  let g:cg_chatgpt_api_key = get(g:, 'cg_chatgpt_api_key', '')
  if len(g:cg_chatgpt_api_key) == 0
    call s:warn('ChatGPT api key is required to be set to `g:cg_chatgpt_api_key`')
    return
  endif

  let l:cmd = s:get_cmd(g:cg_chatgpt_api_key, a:query)
  call s:send_query(l:cmd)
endfunction

function! s:get_cmd(api_key, query) abort
  let l:data = {
  \ 'model': 'gpt-3.5-turbo',
  \ 'messages': [
  \   {
  \     'role': 'user',
  \     'content': a:query,
  \   },
  \ ],
  \}

  let l:json = json_encode(l:data)
	" local escaped_json = string.gsub(json, '"', '\\"')

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

function! s:send_query(cmd) abort
  echo 'CG querying for response...'
  if has('job')
    let Callback = function('s:job_callback', [])
    call job_start(a:cmd, {'close_cb': Callback})
  elseif has('nvim')
    let Callback = function('s:job_callback_nvim', [])
    call jobstart(a:cmd, {'on_stdout': Callback, 'stdout_buffered': 1})
  else
    call s:warn('CS.vim require job feature.')
  endif
endfunction

function! s:job_callback(channel) abort
  let l:response = []
  while ch_status(a:channel, {'part': 'out'}) == 'buffered'
    let l:response += [ch_read(a:channel)]
  endwhile
  call s:process_response(l:response)
endfunction

function! s:job_callback_nvim(id, data, event) abort
  call s:process_response(a:data)
endfunction

function! s:process_response(content) abort
  echom a:content
endfunction

function! s:warn(message) abort
  echohl WarningMsg | echom a:message | echohl None
endfunction
