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
:CG your query     <-  single completion query.
:CGC your query    <-  Chat query, usage will be shown below.
:CGCode your query <-  Similar to `:CGC` but added initial user message to ensure only code reply.
```

# DISCLAIMER

This software is provided "AS IS" and WITHOUT ANY WARRANTY, EXPRESS OR IMPLIED. The author is not liable for any damages or losses arising from the use of the software. The software is not intended to provide professional advice. The author shall not be held accountable for any misuse of the software. By using this software, you agree to be bound by these terms and conditions.

ᓚᘏᗢ . . . miau
