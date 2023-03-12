# CG.vim
* Vim plugin to query to [ChatGPT](https://chat.openai.com/). While there are already a few ChatGPT plugin this plugin aims to similar behavious with [CS.vim](https://github.com/farhanmustar/CS.vim) and [fugitive.vim](https://github.com/tpope/vim-fugitive).
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
