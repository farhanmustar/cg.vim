# CG.vim
* Vim plugin to query to [ChatGPT](https://chat.openai.com/). 
* While there are already a few ChatGPT plugins available, this plugin aims to replicate the behavior of [CS.vim](https://github.com/farhanmustar/CS.vim) and [vim-fugitive](https://github.com/tpope/vim-fugitive). Specifically, the aim is to recreate the commit message buffer behavior in vim-fugitive.
* This plugin make use of ```curl``` application to query information directly from vim. Makesure curl is executable by vim.
* Execute this command in vim to check:
```vim
:echo executable('curl')
```

## Installation
* Installation using [Vundle.vim](https://github.com/VundleVim/Vundle.vim).
```vim
Plugin 'farhanmustar/cg.vim'
```

* Installation using [vim-plug](https://github.com/junegunn/vim-plug).
```vim
Plug 'farhanmustar/cg.vim'
```

### OpenAI API Key
* Users need to supply api key to `g:cg_api_key` variable.
* To supply it directly in .vimrc
```vim
let g:cg_api_key = 'YOUR_SECRET_API_KEY_WAITING_TO_BE_EXPOSED_OR_PUSH_TO_REPO'
```

* To supply it through environment variable where you set the api key to it.
```vim
let g:cg_api_key = getenv('YOUR_ENV_VARIABLE_NAME_THAT_SHOULD_NOT_EXIST')
```

* To supply it through file that contain the api key (assuming it is on the first line). 
```vim
let g:cg_api_key = readfile(glob('~/.PATH_TO_FILE_THAT_SHOULD_NEVER_BE_THERE'))[0]
let g:cg_api_key = trim(g:cg_api_key)
```

## Functionality
* Add 3 new command:
```vim
:CG your query     " single completion query.
:CGC your query    " Chat query, usage will be shown below.
:CGCode your query " Similar to `:CGC` but added initial user message to ensure only code reply.

" Chat Buffer Key Maps (for CGC and CGCode command only).
cc " Open commit buffer to send next message (empty message will treat as cancel new msg)
<  " Navigate to previous conversation.
>  " Navigate to next conversation
```

### Demo 1
* Demonstrate `:CG` command to query for `python method to hash multiple files`.
* Then manually set the opened CG buffer to python filetype for syntax highlighting.
<img src="https://github.com/farhanmustar/cg.vim/wiki/cg_promp.gif" alt="CG Demo" />

### Demo 2
* Demonstrate `:CGC` command to query for `python method to hash multiple files`.
* Then `cc` keymap is pressed to open commit buffer to reply for better answer with the following query:<br>
  `But i want to read all files content then hash temp all into single hash value`
* Then manually set the opened CG buffer to python filetype for syntax highlighting.
<img src="https://github.com/farhanmustar/cg.vim/wiki/cgc_chat.gif" alt="CGC Demo" />

### Demo 3
* Demonstrate `:CGCode` command to query for `python method to hash multiple files`.
* Then `cc` keymap is pressed to open commit buffer to reply for better answer with the following query:<br>
  `But i want to hash all files into single hash value`
* Reply again with following message to cleanup the suggested answer:<br>
  `Can we do it without reading it by chunk`
* Finally navigate to previous and next conversation using `<` and `>` keymap.
<img src="https://github.com/farhanmustar/cg.vim/wiki/cgcode_chat.gif" alt="CGCode Demo" />


# DISCLAIMER

This software is provided "AS IS" and WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED. The author is not liable for any damages or losses arising from the use of the software. The software is not intended to provide professional advice. The author shall not be held accountable for any misuse of the software. By using this software, you agree to be bound by these terms and conditions.

ᓚᘏᗢ . . . miau
