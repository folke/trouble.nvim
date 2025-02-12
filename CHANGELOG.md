# Changelog

## [3.7.1](https://github.com/folke/trouble.nvim/compare/v3.7.0...v3.7.1) (2025-01-28)


### Bug Fixes

* **lsp:** make_position_params with offset encoding. Closes [#606](https://github.com/folke/trouble.nvim/issues/606) ([6f380b8](https://github.com/folke/trouble.nvim/commit/6f380b8826fb819c752c8fd7daaee9ef96d4c689))

## [3.7.0](https://github.com/folke/trouble.nvim/compare/v3.6.0...v3.7.0) (2025-01-15)


### Features

* **config:** add `close` counterparts to jump split actions ([#584](https://github.com/folke/trouble.nvim/issues/584)) ([928e6d0](https://github.com/folke/trouble.nvim/commit/928e6d01c83b87137a7baf7221fdd070aed3b313))
* **preview:** allow sources to decorate the preview buffer/window ([affd249](https://github.com/folke/trouble.nvim/commit/affd249ab579c1380da8513b9f850463c6408e9b))
* **sources:** added snacks picker source ([fa32f71](https://github.com/folke/trouble.nvim/commit/fa32f71be4d6c7c2cd4db5bf89cd836248c7bd67))


### Bug Fixes

* **format:** for "attempt to index local 'signs' (a boolean value)" errors in nvim-0.10.1+ ([#579](https://github.com/folke/trouble.nvim/issues/579)) ([2e7cb80](https://github.com/folke/trouble.nvim/commit/2e7cb80e2a4f64373228b78cb2080c423d771ef8))
* **lsp:** always use actual symbol kind names. See [#568](https://github.com/folke/trouble.nvim/issues/568) ([11bcbc0](https://github.com/folke/trouble.nvim/commit/11bcbc0361420875b8bd803267cd532a350c398b))
* **lsp:** handle invalid line positions ([1a2efaf](https://github.com/folke/trouble.nvim/commit/1a2efaf06d2966ffe3a1ef4a90d0bd8b9d870643))
* **lsp:** use new vim.str_byteindex if available to calculate start positions of LSP ranges ([86746d2](https://github.com/folke/trouble.nvim/commit/86746d2b5890139a0270c6693ece219912fd73c0))
* **lsp:** use old-style args for vim.str_byteindex. Fixes [#604](https://github.com/folke/trouble.nvim/issues/604) ([c633e85](https://github.com/folke/trouble.nvim/commit/c633e8559adf529b85167a4cb489d7358e9efb1a))
* **snacks:** use filtered items instead of all ([2423cd2](https://github.com/folke/trouble.nvim/commit/2423cd20ae2faadec9edd7013617f7b80a3ae628))


### Performance Improvements

* **debug:** don't create obj dumps ([1fe80c7](https://github.com/folke/trouble.nvim/commit/1fe80c7cdf86d6a92ab83c0d1dac1cf8aff68b0d))
* **treesitter:** set regions early ([#587](https://github.com/folke/trouble.nvim/issues/587)) ([20aa858](https://github.com/folke/trouble.nvim/commit/20aa858a86a09458c3851464eab0c5560b5249c0))

## [3.6.0](https://github.com/folke/trouble.nvim/compare/v3.5.2...v3.6.0) (2024-07-21)


### Features

* allow disabling a key ([891e76d](https://github.com/folke/trouble.nvim/commit/891e76df4628d5bb3ad41edb4269592c19b35537))


### Bug Fixes

* **text:** skip treesitter when buf is no longer valid. Fixes [#556](https://github.com/folke/trouble.nvim/issues/556) ([05694b4](https://github.com/folke/trouble.nvim/commit/05694b4e7d67fe1c46503e92a7b812fa58d92702))

## [3.5.2](https://github.com/folke/trouble.nvim/compare/v3.5.1...v3.5.2) (2024-07-19)


### Bug Fixes

* **util:** concealcursor ([e01c99e](https://github.com/folke/trouble.nvim/commit/e01c99eb36c93c77e8985ce9615a75bb73c8c7cf))


### Performance Improvements

* **treesitter:** incremental parsing for highlighter ([85154ce](https://github.com/folke/trouble.nvim/commit/85154cedf9b5bf64e56046d493cad7afc3416621))

## [3.5.1](https://github.com/folke/trouble.nvim/compare/v3.5.0...v3.5.1) (2024-07-04)


### Bug Fixes

* **command:** weird issue with number keys. no idea when this happens. oh well... Fixes [#528](https://github.com/folke/trouble.nvim/issues/528) ([95568c6](https://github.com/folke/trouble.nvim/commit/95568c61416ff3dea2b6177deeb8a51130d6fd7a))
* **diagnostics:** ruff generates a `vim.NIL` diag code. Closes [#527](https://github.com/folke/trouble.nvim/issues/527) ([edd9684](https://github.com/folke/trouble.nvim/commit/edd9684089b19684d5dad90bd5fcfceb48719212))
* **lsp:** use caller text for call locations in incoming lsp calls. Fixes [#529](https://github.com/folke/trouble.nvim/issues/529) ([12dc19a](https://github.com/folke/trouble.nvim/commit/12dc19a8aba6f964fc6c4060649782a2e57de0cf))

## [3.5.0](https://github.com/folke/trouble.nvim/compare/v3.4.3...v3.5.0) (2024-07-04)


### Features

* added explicit support for mini.icons ([42dcb58](https://github.com/folke/trouble.nvim/commit/42dcb58e95723f833135d5cf406c38bd54304389))


### Bug Fixes

* **telescope:** item path. Fixes [#521](https://github.com/folke/trouble.nvim/issues/521) ([6e19371](https://github.com/folke/trouble.nvim/commit/6e1937138b2c292ac0d3e8d9bfc36a29a515a380))
* **telescope:** use (lnum, 0) for telescope item without col ([#524](https://github.com/folke/trouble.nvim/issues/524)) ([25204b7](https://github.com/folke/trouble.nvim/commit/25204b7e134005dfcb694a0b6d227c98ce3ad164))

## [3.4.3](https://github.com/folke/trouble.nvim/compare/v3.4.2...v3.4.3) (2024-06-23)


### Bug Fixes

* **item:** empty filenames ([77f17d1](https://github.com/folke/trouble.nvim/commit/77f17d1bb29b32e06f75afa5c4fe0eba6f5ab397))
* **promise:** vim.loop. Fixes [#513](https://github.com/folke/trouble.nvim/issues/513) ([1acfb6c](https://github.com/folke/trouble.nvim/commit/1acfb6c45c38f07f4d0a5e4cbdd60c9bb6880908))
* **util:** crlf. Fixes [#518](https://github.com/folke/trouble.nvim/issues/518) ([032fa2c](https://github.com/folke/trouble.nvim/commit/032fa2c36a7c8738eb1e1d2f52a433be085f603a))
* **utils:** use `vim.loop or vim.ev` declared in the beginning of a file ([#519](https://github.com/folke/trouble.nvim/issues/519)) ([235dc61](https://github.com/folke/trouble.nvim/commit/235dc61cf49b61e7970897c3eed51b1b30121b9e))

## [3.4.2](https://github.com/folke/trouble.nvim/compare/v3.4.1...v3.4.2) (2024-06-14)


### Bug Fixes

* correct invalid float positions. Fixes [#502](https://github.com/folke/trouble.nvim/issues/502) ([88a40f1](https://github.com/folke/trouble.nvim/commit/88a40f1cc3af846b520ae167f0177b5faa148c86))
* **diagnostics:** custom format for code. Fixes [#508](https://github.com/folke/trouble.nvim/issues/508) ([ada78fa](https://github.com/folke/trouble.nvim/commit/ada78fae41fc05d52883f19fb5e22d5a61e0ef08))
* fixup ([60b0ac3](https://github.com/folke/trouble.nvim/commit/60b0ac3772e991bc194207afc28368a5f15d913a))
* **highlights:** link TroubleBasename to TroubleFilename. Fixes [#507](https://github.com/folke/trouble.nvim/issues/507) ([276e7b7](https://github.com/folke/trouble.nvim/commit/276e7b7a8764cd59de5c8a588771a54a979ab3c3))
* **main:** handle windows with changed buffers ([286c044](https://github.com/folke/trouble.nvim/commit/286c04474cbb24894d233e6b0c00f1e6c8d2ae54))
* **view:** dont go to main when not in the trouble window when closing ([8d5e05c](https://github.com/folke/trouble.nvim/commit/8d5e05c0d0ce7a2c630ce92cb3cc923044848063))

## [3.4.1](https://github.com/folke/trouble.nvim/compare/v3.4.0...v3.4.1) (2024-06-12)


### Bug Fixes

* **fzf:** added descriptions ([5e45bb7](https://github.com/folke/trouble.nvim/commit/5e45bb78f8da3444d35616934c180fce3742c439))

## [3.4.0](https://github.com/folke/trouble.nvim/compare/v3.3.0...v3.4.0) (2024-06-11)


### Features

* added fzf-lua integration ([d14323f](https://github.com/folke/trouble.nvim/commit/d14323fe3461b89e91fb569148b44731655ae196))
* **fzf-lua:** added smart open/add that will use selection or all when nothing selected. ([bed3c5b](https://github.com/folke/trouble.nvim/commit/bed3c5b79298d94d4981d86ed699c70f58ceccff))


### Bug Fixes

* **fzf-lua:** smart-open on windows ([4d0f045](https://github.com/folke/trouble.nvim/commit/4d0f0454ae2a246ec3e0ff541a347164dac23b7b))
* initialize `auto_open`. Fixes [#489](https://github.com/folke/trouble.nvim/issues/489) ([0793267](https://github.com/folke/trouble.nvim/commit/0793267d3d4b782e46161931b7cbaaf062a892d7))
* **spec:** properly process actions. Fixes [#494](https://github.com/folke/trouble.nvim/issues/494) ([3082f4b](https://github.com/folke/trouble.nvim/commit/3082f4b10fe9f0a8aa922065b998bc37115c4bef))
* **telescope:** autmatically select telescope_files mode if list are files without locations. Fixes [#466](https://github.com/folke/trouble.nvim/issues/466) ([1ad6b14](https://github.com/folke/trouble.nvim/commit/1ad6b141316f90a658c6d654516092d43e3e596c))
* **telescope:** set end_pos to end of word ([4deb811](https://github.com/folke/trouble.nvim/commit/4deb8111e7ffa48a4a27bad1ecdfb7779f4efb7d))
* **views:** pending should be considered open. Fixes [#492](https://github.com/folke/trouble.nvim/issues/492) ([57b50a6](https://github.com/folke/trouble.nvim/commit/57b50a6dc129f3a82c3bdd9f81b9f2d4e770ac09))

## [3.3.0](https://github.com/folke/trouble.nvim/compare/v3.2.0...v3.3.0) (2024-06-07)


### Features

* **lsp:** most lsp sources now support `params.include_current`. Fixes [#482](https://github.com/folke/trouble.nvim/issues/482) ([29d19d4](https://github.com/folke/trouble.nvim/commit/29d19d4f2102306176578f1fe537fbd9740b19e1))
* **window:** more options for mapping keys ([fdcfc5a](https://github.com/folke/trouble.nvim/commit/fdcfc5a200491e9509e56e04c6b3cdee8ada3153))
* you can now use `dd` and `d` to delete items in the trouble list. Fixes [#149](https://github.com/folke/trouble.nvim/issues/149). Fixes [#347](https://github.com/folke/trouble.nvim/issues/347) ([e879302](https://github.com/folke/trouble.nvim/commit/e879302d003bf5bda746a36365431d4a72cf3226))


### Bug Fixes

* **api:** only refresh on open if there's no action. Fixes [#488](https://github.com/folke/trouble.nvim/issues/488) ([2661f46](https://github.com/folke/trouble.nvim/commit/2661f4612209cbbc1106fb9537666ea0133e4859))
* **preview:** fixed mouse clicks in the preview main window. Fixes [#484](https://github.com/folke/trouble.nvim/issues/484) ([98d9ed7](https://github.com/folke/trouble.nvim/commit/98d9ed74aec4e82171de3ae0541cdd078558e546))
* **telescope:** show error when use tries to add when telescope picker does not exist ([c11dc27](https://github.com/folke/trouble.nvim/commit/c11dc2777d52da2c8da25836817e43608ec951a5))
* use vim.loop for nvim 0.9 in view/init.lua ([#487](https://github.com/folke/trouble.nvim/issues/487)) ([791278e](https://github.com/folke/trouble.nvim/commit/791278e498e1147520e4214982767f77ca4a99df))
* **view:** when calling open when the view is already open, do a refresh. See [#485](https://github.com/folke/trouble.nvim/issues/485) ([39595e8](https://github.com/folke/trouble.nvim/commit/39595e883e2f91456413ca4df287575d31665940))

## [3.2.0](https://github.com/folke/trouble.nvim/compare/v3.1.0...v3.2.0) (2024-06-06)


### Features

* **lsp:** add incoming/outgoing calls to lsp mode ([8adafc1](https://github.com/folke/trouble.nvim/commit/8adafc14d8fe2a4471a0311ff72927250390d7bd))
* **lsp:** added support for showing locations from lsp execute commands ([b1d16ac](https://github.com/folke/trouble.nvim/commit/b1d16ac02d787e40165130e0cd09474ce639b175))
* promise class ([84f0c6d](https://github.com/folke/trouble.nvim/commit/84f0c6d047dbf182622f3d89bc47ec4a70c900b2))


### Bug Fixes

* **api:** show error when an invalid mode was used. Fixes [#465](https://github.com/folke/trouble.nvim/issues/465) ([4b1914c](https://github.com/folke/trouble.nvim/commit/4b1914c5cdbf7be18fee797c410df2faa2be13f2))
* **format:** pos format. See [#472](https://github.com/folke/trouble.nvim/issues/472) ([abdfa1d](https://github.com/folke/trouble.nvim/commit/abdfa1daeb9713470a9b61676a82f24f32e31900))
* **lsp:** check for nil on faulty lsp results ([d7f69ff](https://github.com/folke/trouble.nvim/commit/d7f69ff5638cf1864cabac54ade1b1694adfe085))
* **lsp:** dont process nil results ([06a4892](https://github.com/folke/trouble.nvim/commit/06a48922e83b114a78c63ec770819b4afacd2166))
* **lsp:** send request only to needed clients ([c147a75](https://github.com/folke/trouble.nvim/commit/c147a75c421b2df6986d82f61657ccec2f302091))
* **lsp:** use document uri of document symbols don't have an uri set. Fixes [#480](https://github.com/folke/trouble.nvim/issues/480) ([358f0ee](https://github.com/folke/trouble.nvim/commit/358f0ee6ce4c379a3b0c37bb04ab6587c86e285a))
* **preview:** hide winbar when previewing in main. Fixes [#464](https://github.com/folke/trouble.nvim/issues/464) ([250ea79](https://github.com/folke/trouble.nvim/commit/250ea79c810a3e5fff846c788792441f1c795c92))
* **preview:** respect fold settings. Fixes [#459](https://github.com/folke/trouble.nvim/issues/459) ([29d1bb8](https://github.com/folke/trouble.nvim/commit/29d1bb81adc847e89ddbbf5b11ff0079daf7cc0a))
* **preview:** set correct extmark priorities in preview highlight. Fixes [#476](https://github.com/folke/trouble.nvim/issues/476) ([13ad959](https://github.com/folke/trouble.nvim/commit/13ad95902cf479b0fa091a77368af0e03b486fe3))
* **view:** correctly set folding options to wo. See [#477](https://github.com/folke/trouble.nvim/issues/477) ([9151797](https://github.com/folke/trouble.nvim/commit/915179759c9459b69faae90a38da6fc1ca6b90d7))
* **view:** ensure fold settings are correct for the trouble views. See [#477](https://github.com/folke/trouble.nvim/issues/477) ([b5181b6](https://github.com/folke/trouble.nvim/commit/b5181b65912c704d5378f8fe6889924f0182c357))
* **view:** execute actions on first render ([97bfb74](https://github.com/folke/trouble.nvim/commit/97bfb74826476b26634b5321c5d8dfbc46e41497))
* **window:** account for winbar for preview in main. Fixes [#468](https://github.com/folke/trouble.nvim/issues/468) ([23ded52](https://github.com/folke/trouble.nvim/commit/23ded52593d017fd7d6042215460419801e35481))
* **window:** set default winblend=0. See [#468](https://github.com/folke/trouble.nvim/issues/468) ([e296940](https://github.com/folke/trouble.nvim/commit/e2969409cf3f38f69913cc8fd9aa13137aabe760))


### Performance Improvements

* use promises for fetching sections ([e49a490](https://github.com/folke/trouble.nvim/commit/e49a49044cca072c4aca1cb3a5013aa92ac3b4f9))

## [3.1.0](https://github.com/folke/trouble.nvim/compare/v3.0.0...v3.1.0) (2024-05-31)


### Features

* added severity filter keymap and improved filtering actions ([7842dbb](https://github.com/folke/trouble.nvim/commit/7842dbb70f088cbaae969004bd2fbae09b2a2d26))
* only open trouble when results (optionally). Fixes [#450](https://github.com/folke/trouble.nvim/issues/450) ([8fbd2ab](https://github.com/folke/trouble.nvim/commit/8fbd2abb3ff42ebb134e389f405bfa9140db1fe3))
* **telescope:** allow passing additional trouble options to telescope open/add. Fixes [#457](https://github.com/folke/trouble.nvim/issues/457) ([4eaaf9c](https://github.com/folke/trouble.nvim/commit/4eaaf9cf8b967010998ccfc4af525b3e6d70b8b5))


### Bug Fixes

* close section session when needed ([2caf73d](https://github.com/folke/trouble.nvim/commit/2caf73d2d136625d77c0d25cc3b5d5e1e0bef3d0))
* **fold:** start folding with closest non leaf node. Fixes [#420](https://github.com/folke/trouble.nvim/issues/420) ([f248c69](https://github.com/folke/trouble.nvim/commit/f248c6941ba5a48be531cbb25aac32e1042c65ad))
* **follow:** improve the way follow works ([cf81aac](https://github.com/folke/trouble.nvim/commit/cf81aaca820017388fc630c534774c95b58233f2))
* **format:** compat old signs ([0e843ed](https://github.com/folke/trouble.nvim/commit/0e843edbdc1b25ca6a5468d636b22e7035a4ad69))
* **format:** fallback to sign_defined. Fixes [#448](https://github.com/folke/trouble.nvim/issues/448) ([36545cb](https://github.com/folke/trouble.nvim/commit/36545cb88fa999f211bfc341998f501803bf5434))
* **lsp:** batch get offset position for lsp results. See [#452](https://github.com/folke/trouble.nvim/issues/452) ([96c30dc](https://github.com/folke/trouble.nvim/commit/96c30dc6ae10e42ab47c1f68d7f715bf01100c48))
* **lsp:** correctly clear location cache ([7ea94a6](https://github.com/folke/trouble.nvim/commit/7ea94a6366141878758938010e4a0818a56721ad))
* **lsp:** exclude locations that match the current line ([8c03e13](https://github.com/folke/trouble.nvim/commit/8c03e133bc88fb7c242e9915d06f0a8978511c29))
* make sure line is always a string passed to get_line_col ([5a12185](https://github.com/folke/trouble.nvim/commit/5a12185787896da209738bd41cbe4133d82ce9bb))
* **preview:** correctly load non-scratch buffers ([965f56f](https://github.com/folke/trouble.nvim/commit/965f56f3e17baee4213cf50637f92de4be32d8e9))
* **preview:** correctly pass options to create scratch buffers. Fixes [#451](https://github.com/folke/trouble.nvim/issues/451) ([c50c7e3](https://github.com/folke/trouble.nvim/commit/c50c7e35d4f504d6336875994109c546ff0634b5))
* **preview:** don't error on invalid positions ([6112c3c](https://github.com/folke/trouble.nvim/commit/6112c3c5c903a05178276a083edc756ba3cb65a0))
* **qf:** only listen for TextChanged in the main buffer. See [#201](https://github.com/folke/trouble.nvim/issues/201) ([f75992f](https://github.com/folke/trouble.nvim/commit/f75992f9a1b93cc4490dca28f93acc921c25419e))
* **qf:** update qflist on TextChanged to update pos. Fixes [#201](https://github.com/folke/trouble.nvim/issues/201) ([c1d9294](https://github.com/folke/trouble.nvim/commit/c1d9294eb73479fd4007237613eb7e945cd84e20))
* stop ([bda8de4](https://github.com/folke/trouble.nvim/commit/bda8de4205f06c3939b8b59e4da1f3713d04ea05))
* **telescope:** remove filter on `buf = 0`. See [#399](https://github.com/folke/trouble.nvim/issues/399) ([f776ab0](https://github.com/folke/trouble.nvim/commit/f776ab0ff1658f052b7345d4bbd5961b443ea8a0))
* **view:** restore loc on first render and dont delete last loc if trouble window was never visisted. See [#367](https://github.com/folke/trouble.nvim/issues/367) ([51bf510](https://github.com/folke/trouble.nvim/commit/51bf51068d929173157ebcfb863115760c837355))


### Performance Improvements

* **lsp:** cache location requests ([6053627](https://github.com/folke/trouble.nvim/commit/6053627943020d9774c75ec637eb06847a79c7a1))
* **lsp:** optimize batch fetching lsp item locations. Fixes [#452](https://github.com/folke/trouble.nvim/issues/452) ([a6f1af5](https://github.com/folke/trouble.nvim/commit/a6f1af567fc987306f0f328e78651bab1bfe874e))
* much faster treesitter highlighter ([d4de08d](https://github.com/folke/trouble.nvim/commit/d4de08d9314a9ddf7278ee16efb58d0efe332bc8))
* prevent autocmd leaks ([9e3391c](https://github.com/folke/trouble.nvim/commit/9e3391ce735f4f6fa98fe70ba9a3e444f2fd539a))
* **preview:** re-use existing preview when preview is for the same file ([a415b64](https://github.com/folke/trouble.nvim/commit/a415b64b8a702ab6388e3aaaf16306750fc53f79))

## [3.0.0](https://github.com/folke/trouble.nvim/compare/v2.10.0...v3.0.0) (2024-05-30)


### ⚠ BREAKING CHANGES

* Trouble v3 is now merged in main. You may need to update your configs.

### Features

* `Trouble` now shows vim.ui.select to chose a mode ([0189184](https://github.com/folke/trouble.nvim/commit/01891844a9adb3b5b2de508724024d516a2b891a))
* added basename/dirname ([bb3740a](https://github.com/folke/trouble.nvim/commit/bb3740a1c41e83bcd59c3fe04714a85b445c4742))
* added help ([68ac238](https://github.com/folke/trouble.nvim/commit/68ac238aeef333a37dc95d875bed46a2698793d5))
* added kind symbol highlights ([de08657](https://github.com/folke/trouble.nvim/commit/de086574208b19b762055487334ce50ca95cc008))
* added lpeg parser for parsing `:Trouble` args into lua tables ([b25ef53](https://github.com/folke/trouble.nvim/commit/b25ef53117b0bdc5733d26e42a55c7f32daadbe5))
* added missing fold keymaps. folding is now feature complete ([9fb1be0](https://github.com/folke/trouble.nvim/commit/9fb1be0915202989bd17e0c9768be23ae7b15010))
* added multiline option back ([d80e978](https://github.com/folke/trouble.nvim/commit/d80e978f70cc3c026ad028dafbde9e3ad45ba54c))
* added proper api ([a327003](https://github.com/folke/trouble.nvim/commit/a3270035999dc965176ccd140dcc9afe57f0934a))
* added support for formatting fields with a treesitter language ([21cfee9](https://github.com/folke/trouble.nvim/commit/21cfee9e4e026482c1c9719156aae3152b2c590a))
* allow items without buf ([c3b01ce](https://github.com/folke/trouble.nvim/commit/c3b01ce7662dda3a542c52aa1521f8467300c84a))
* allow top-level filter ([12447df](https://github.com/folke/trouble.nvim/commit/12447df2a81205b8bda12dd1c9271c1c0059184f))
* **config:** added `auto_jump` to jump to the item when there's only one. Fixes [#409](https://github.com/folke/trouble.nvim/issues/409) ([94a84ab](https://github.com/folke/trouble.nvim/commit/94a84ab884757b1a9f697807e7bdace8b8919afb))
* **config:** added keymap to inspect an item. Useful for dev ([9da1a47](https://github.com/folke/trouble.nvim/commit/9da1a4783bc0d87427f5cbf6964321774e0bb1bc))
* **config:** set `focus=false` by default ([c7e5398](https://github.com/folke/trouble.nvim/commit/c7e539819e6d21428a747f46715a23b3d1a204b6))
* **diagnostics:** added support for diagnostics signs on Neovim &gt;= 0.10.0. Fixes [#369](https://github.com/folke/trouble.nvim/issues/369), fixes [#389](https://github.com/folke/trouble.nvim/issues/389) ([6303740](https://github.com/folke/trouble.nvim/commit/6303740eb1a0730b5654d554ba38bd9614c87e28))
* **filter:** added filetype filter ([e541444](https://github.com/folke/trouble.nvim/commit/e5414444bdbd5fb70a954ad24abeaa0866179f62))
* **filter:** easier filtering of any values ([1b528d8](https://github.com/folke/trouble.nvim/commit/1b528d8f3b91fe07ab4f27cbe8eee65b0532192b))
* **filter:** range filter ([34a06d6](https://github.com/folke/trouble.nvim/commit/34a06d6f4bd32b37f685a36a5037c1556ce6b88f))
* filters, formatters and sorters are now configurable ([c16679d](https://github.com/folke/trouble.nvim/commit/c16679ddf67f28b5df0735f488497a4c1e7881ee))
* **format:** formats now support `{one|two}`. First field that returns a value will be used ([26ad82e](https://github.com/folke/trouble.nvim/commit/26ad82eb3c81a434ade3d7bebd97e02565ac717e))
* global view filters and easy toggling of just items of the current buffer ([11e7c39](https://github.com/folke/trouble.nvim/commit/11e7c39803ff33c68346019a46172fe9be5f3f6d))
* improved commandline parser and completion ([f7eccfb](https://github.com/folke/trouble.nvim/commit/f7eccfbddef64f3379cf6997617cb41e3005f355))
* initial commit of rewrite ([d9542ca](https://github.com/folke/trouble.nvim/commit/d9542ca97e37a43844d9088bf453bbb257de423c))
* item hierarchies and directory grouping ([d2ed413](https://github.com/folke/trouble.nvim/commit/d2ed41320e548149d024634d8a6aa1b5c40396a1))
* Item.get_lang and Item.get_ft ([498da6b](https://github.com/folke/trouble.nvim/commit/498da6bcff8170f620506f66dd71465b3565baaa))
* **item:** util method to add missing text to items ([de9e7e6](https://github.com/folke/trouble.nvim/commit/de9e7e68ebb7aa36d78a68207d42943d49a31a85))
* **lsp:** added `lsp_incoming_calls` and `lsp_outgoing_calls`. Closes [#222](https://github.com/folke/trouble.nvim/issues/222) ([b855469](https://github.com/folke/trouble.nvim/commit/b855469429f10c74a3314432ba2735a32115cbb2))
* **lsp:** document symbols caching and compat with Neovim 0.9.5 ([2f49b92](https://github.com/folke/trouble.nvim/commit/2f49b920b0822a3d06c25d24d840830016168a82))
* main window tracking ([23a0631](https://github.com/folke/trouble.nvim/commit/23a06316607fe2d2ab311fdb5bb45157c2d8ec91))
* make the preview action a toggle ([86da179](https://github.com/folke/trouble.nvim/commit/86da1794855f71ec592efec2a6a65911f08892a2))
* preview can now be shown in a split/float ([e2919eb](https://github.com/folke/trouble.nvim/commit/e2919eb565ccc66d4adad729b4e323a718d41953))
* preview is now fully configurable ([b99110a](https://github.com/folke/trouble.nvim/commit/b99110adc3815f1b7b8fe3dd40f4c9da315f7cca))
* **preview:** option to force loading real buffers in preview. Fixes [#435](https://github.com/folke/trouble.nvim/issues/435) ([ccacba2](https://github.com/folke/trouble.nvim/commit/ccacba22b2c1946cfe1b9f767f7880bcd031ad7c))
* **preview:** use a float to show preview in the main window instead of messing with the main window itself ([9e0311d](https://github.com/folke/trouble.nvim/commit/9e0311d177af7cd6750d88280d589ceca4f7685a))
* **preview:** window var to know a window is a preview win ([dcecbb9](https://github.com/folke/trouble.nvim/commit/dcecbb9b9d67770c8df4c1c49b91631fbdae8ae5))
* **qf:** add treesitter highlighting to quickfix/loclist. Fixes [#441](https://github.com/folke/trouble.nvim/issues/441) ([325d681](https://github.com/folke/trouble.nvim/commit/325d681953611336cdfdf08a3d71e5125c5f89a5))
* **render:** `{field:ts}` will now use the treesitter lang of the item buffer for highlighting ([21af85c](https://github.com/folke/trouble.nvim/commit/21af85cc97860e3bcf157891c2598af517f9b421))
* **render:** added support for rendering multiple sections ([332b25b](https://github.com/folke/trouble.nvim/commit/332b25b09c7159a82322ec97f7aa1717133ffa6f))
* **source:** added lsp source ([3969907](https://github.com/folke/trouble.nvim/commit/39699074cd18cdeb5e9a29e80ffd2d239c58ac7e))
* **source:** added quickfix source ([3507b7b](https://github.com/folke/trouble.nvim/commit/3507b7b694ddee5921c7004c6bed0b71ab8e0920))
* **sources:** added support for loading external sources ([89ac6f1](https://github.com/folke/trouble.nvim/commit/89ac6f1a7f238ca65d964569786b205a496ad213))
* **sources:** added telescope source ([39069e2](https://github.com/folke/trouble.nvim/commit/39069e2f4139c7ae28cf7e16fe610b8462fb3939))
* **source:** sources can now have multiple child sources ([c433301](https://github.com/folke/trouble.nvim/commit/c4333014a770eca5a66c7685f4063d8de13517db))
* **source:** sources now always execute in the context of the main window even when a preview is active ([4eab561](https://github.com/folke/trouble.nvim/commit/4eab56122bb335a5627405791e4691af5043493e))
* **statusline:** added statusline component ([5c0b163](https://github.com/folke/trouble.nvim/commit/5c0b1639c83266427489bb515bffd8b8bc055809))
* **statusline:** allow 'fixing' the statusline bg color based on a hl_group. Fixes [#411](https://github.com/folke/trouble.nvim/issues/411) ([986b44d](https://github.com/folke/trouble.nvim/commit/986b44d4471ee8b8a708a0172fb0829a9c858543))
* **statusline:** statusline api ([c219a1a](https://github.com/folke/trouble.nvim/commit/c219a1a9f56a70ac55e89325c333fcfd0616ea97))
* **telescope:** added option to add telescope results to trouble, without clearing the existing results. Fixes [#370](https://github.com/folke/trouble.nvim/issues/370) ([a7119ab](https://github.com/folke/trouble.nvim/commit/a7119abb0cd1b1ef058fc99c036230bbe153504f))
* **tree:** added `flatten()` to get all items from the tree ([35c0236](https://github.com/folke/trouble.nvim/commit/35c0236ceb78fc37a94f5882f736416ebb15c306))
* Trouble v3 is now merged in main. You may need to update your configs. ([1b362b8](https://github.com/folke/trouble.nvim/commit/1b362b861eacb9b2367ce92129fad86352707311))
* **util:** better notify functions ([c68c915](https://github.com/folke/trouble.nvim/commit/c68c915353dc5162e5d7494b5ca0919f0e336318))
* **util:** fast get_lines for a buffer ([6940cd8](https://github.com/folke/trouble.nvim/commit/6940cd8c6913e834254e7221ede0ca6a38c81fc0))
* **util:** fast plain text split ([6a30aec](https://github.com/folke/trouble.nvim/commit/6a30aec15ca90e8b396a381f8f1b7c452f6ce68a))
* **util:** make throttles configurable ([8c297c1](https://github.com/folke/trouble.nvim/commit/8c297c171547e8c81fc918a7f31b3c2a8ce58512))
* **view:** added support for pinned views. Main window of the view will stay the same as long as its a valid window ([17131e2](https://github.com/folke/trouble.nvim/commit/17131e2b9a0b7d17046cb9b7ed9b7eeb36b6423a))
* **view:** expose some params in the trouble window var. Fixes [#357](https://github.com/folke/trouble.nvim/issues/357) ([a4b9849](https://github.com/folke/trouble.nvim/commit/a4b9849ce7ec14213069034403f5fc96d174046b))
* **view:** follow now also scrolls to the file in the list when not on an item ([30b939e](https://github.com/folke/trouble.nvim/commit/30b939efebd8559e9e84c95e3658c447f702b1c2))
* **view:** follow the current item in the list ([e76e280](https://github.com/folke/trouble.nvim/commit/e76e280701e643e8a3074edcb86e819298e7df12))
* **view:** when toggling a trouble list, restore to the last location. Fixes [#367](https://github.com/folke/trouble.nvim/issues/367) ([1d951f5](https://github.com/folke/trouble.nvim/commit/1d951f5c13fd56933e9170b84bfcbbf8ca1a582b))
* **window:** added possibility to override TroubleNormalNC. Fixes [#216](https://github.com/folke/trouble.nvim/issues/216) ([daa5157](https://github.com/folke/trouble.nvim/commit/daa5157e3f0f6cf80ca473d7e43bd73734d6594d))
* **window:** added support for showing a floating window over the main window ([3525169](https://github.com/folke/trouble.nvim/commit/35251698e7836ecb3ee981efe2efe7bcb64ca5f3))
* **window:** allow setting width/height a size for splits. either will be used based on position ([e8ee9b0](https://github.com/folke/trouble.nvim/commit/e8ee9b01ee46f9cd2e2a8fe8b883320f3212608d))
* **window:** expose some window vars for integration with other plugins (edgy.nvim) ([aae1da8](https://github.com/folke/trouble.nvim/commit/aae1da81cba50ca207ce3681e5ef927bd369f074))


### Bug Fixes

* add vim to parser globals ([6077342](https://github.com/folke/trouble.nvim/commit/6077342efe9e7f77756dd064cdb2129ffea5674f))
* **api:** make sure new=true works when opening with a mode string ([398ac76](https://github.com/folke/trouble.nvim/commit/398ac76019a74bbbe0c2b77c0a0a7a1e4ce71c3d))
* better defaults for lsp/diagnostics ([569416d](https://github.com/folke/trouble.nvim/commit/569416d52f1953c35ba8494d7cab2be1b01fe409))
* better way of creating preview buffers ([667b010](https://github.com/folke/trouble.nvim/commit/667b010ba81d7ce49fa2cca6cb80c0b85b328543))
* **command:** improved command completion ([9f59aac](https://github.com/folke/trouble.nvim/commit/9f59aac5ccdb3b5c2c1425176e0112efd7b84a16))
* **commmand:** show mode descriptions ([ce488b9](https://github.com/folke/trouble.nvim/commit/ce488b9b4ddc0f9a61d48d0ae8974c22e5472e0c))
* **config:** fixed some highlights to use the latest treesitter hl groups ([63313cd](https://github.com/folke/trouble.nvim/commit/63313cd5a1e55d1ec870f9716f2e6cc9b6471cfc))
* deprecated tbl_islist ([#436](https://github.com/folke/trouble.nvim/issues/436)) ([5aa7993](https://github.com/folke/trouble.nvim/commit/5aa79935f1de301ed3592981ad7031c166cc5c84))
* diagnostics sections ([27efb63](https://github.com/folke/trouble.nvim/commit/27efb6326d8bb9019d2b69e737c1c3741a3af568))
* **diagnostics:** use main buffer for buffer-local diags ([259770d](https://github.com/folke/trouble.nvim/commit/259770dd860fd08007d13c116a5a7ee985e5f5bf))
* **filter:** fix range filter to include col ([6cae8af](https://github.com/folke/trouble.nvim/commit/6cae8af72ccf1be72718d3f735a467bff23c9beb))
* **filter:** range should also check that the buffer is the same ([fdd27d8](https://github.com/folke/trouble.nvim/commit/fdd27d8ac5276147b91cee2c2578b178a3dd7be2))
* **format:** always pass a valid buffer to ftdetect even just the current onw ([b01b11e](https://github.com/folke/trouble.nvim/commit/b01b11efc901dc3bc5f89d164de5eb71d56cc257))
* **help:** sort keymaps case incensitive ([5d81927](https://github.com/folke/trouble.nvim/commit/5d81927bc7eb9de085d9ea6cf8b977616694f771))
* **highlights:** reset statusline hl groups when colorscheme changes ([a665272](https://github.com/folke/trouble.nvim/commit/a665272b1e1d4b06b1b6824cc3f853874b06c0a1))
* **item:** clamp pos ([6c0204c](https://github.com/folke/trouble.nvim/commit/6c0204cb7d758d70edc5b88919f19a76de853aa7))
* **jump:** save current main cursor to jump list before jumping. Fixes [#385](https://github.com/folke/trouble.nvim/issues/385) ([bd8bfc8](https://github.com/folke/trouble.nvim/commit/bd8bfc8abedbf992a6d8c0db941780e1a79d3b41))
* **lsp:** check if buf is still valid after receiving document symbols ([33ec71c](https://github.com/folke/trouble.nvim/commit/33ec71cf377c518d8b8c022e2b46511f85c3a47d))
* **lsp:** handle invalid positions. Fixes [#434](https://github.com/folke/trouble.nvim/issues/434) ([371cf26](https://github.com/folke/trouble.nvim/commit/371cf26bcbddb39e2e91d69dae90a480f29c3fc0))
* **lsp:** refresh on LspAttach ([17afc44](https://github.com/folke/trouble.nvim/commit/17afc44fc317449128f1804ea6f316ce457295cc))
* **main:** always return a main window, even when no main. Fixes [#426](https://github.com/folke/trouble.nvim/issues/426) ([bda72a5](https://github.com/folke/trouble.nvim/commit/bda72a548e4eb9cab3bcf567ca965b21a136263d))
* make focus the default ([ba1ae49](https://github.com/folke/trouble.nvim/commit/ba1ae497e1899af0e57adb815ab30e37b73d0b76))
* **parser:** handle empty args ([e667da7](https://github.com/folke/trouble.nvim/commit/e667da705c64509347829326d19668e3276355e9))
* **preview:** better preview for multiline items ([60c9fdc](https://github.com/folke/trouble.nvim/commit/60c9fdcad7003fe6ed6f4a225bf709acd19068df))
* **preview:** center preview location and open folds. See [#408](https://github.com/folke/trouble.nvim/issues/408) ([a87fa2a](https://github.com/folke/trouble.nvim/commit/a87fa2ae521d058ad67dc7610efdd234b792d6ef))
* **preview:** clear highlights of preview buffer ([d590491](https://github.com/folke/trouble.nvim/commit/d590491de9515caf5ec3a3a0bd0fdb3047b1fda3))
* **preview:** dont show preview for directories. Fixes [#410](https://github.com/folke/trouble.nvim/issues/410) ([769ee0f](https://github.com/folke/trouble.nvim/commit/769ee0f632ea3b6ffc5716590a711db340e80caf))
* **preview:** fixup for directory check ([eed25b2](https://github.com/folke/trouble.nvim/commit/eed25b2bcea6e59e5f5c92c184ac08be4590b6de))
* **preview:** pass valid buffer so that ftdetect works for ts files. See [#435](https://github.com/folke/trouble.nvim/issues/435) ([65f2430](https://github.com/folke/trouble.nvim/commit/65f2430f6d6276832ec9500b5eafabb01e17d01a))
* **preview:** set correct winhighlight for preview window in main. See [#408](https://github.com/folke/trouble.nvim/issues/408) ([8c3c1db](https://github.com/folke/trouble.nvim/commit/8c3c1db742e74f0e48134cd4e84c976c2706e6b6))
* **preview:** unload preview buffer again when closing and when it wasnt loaded before ([8cc680a](https://github.com/folke/trouble.nvim/commit/8cc680a25f30e63c9e92005155c7916b9a000ac9))
* proper deprecated fix ffs... Fixes [#438](https://github.com/folke/trouble.nvim/issues/438) ([a8264a6](https://github.com/folke/trouble.nvim/commit/a8264a65a0b894832ea642844f5b7c30112c458f))
* properly deal with multiline treesitter segments ([31681a9](https://github.com/folke/trouble.nvim/commit/31681a92e2e7fa0537284ad1516561b46cdb4a24))
* **qf:** col/row offsets ([8ad817f](https://github.com/folke/trouble.nvim/commit/8ad817f12b4c9c4d6bd239c963cda3ac518d272a))
* remove `buf = 0` sorting since it acts weirdly with next/prev ([2b589e9](https://github.com/folke/trouble.nvim/commit/2b589e938c4b5245d7f74b7f23293645e566cee3))
* remove space from `zz zv` command ([ca2cd56](https://github.com/folke/trouble.nvim/commit/ca2cd56d14df8fc619ba44bebd5334d78b57d74c))
* require Neovim &gt;= 0.9.2 ([2448521](https://github.com/folke/trouble.nvim/commit/24485219198a1ab10731e45229f2736ec3242231))
* **section:** dont trigger on invalid buffers ([29ee890](https://github.com/folke/trouble.nvim/commit/29ee890b28280b0a8a504571596a0508244122e1))
* **setup:** add check for NEovim 0.10.0 or markdown parsers. Fixes [#413](https://github.com/folke/trouble.nvim/issues/413) ([6267ef1](https://github.com/folke/trouble.nvim/commit/6267ef15e98bd8df29be7a8d6f47b0e724ceaaaf))
* **sources:** always load sources when not registered yet. Fixes [#393](https://github.com/folke/trouble.nvim/issues/393) ([1470302](https://github.com/folke/trouble.nvim/commit/1470302bd7eef110aef3710dfc8808bc3c3a2179))
* specs and tests ([315f624](https://github.com/folke/trouble.nvim/commit/315f624492c54f9893631459fc79e6c0b33b7cad))
* **statusline:** double escape `#`. Fixes [#424](https://github.com/folke/trouble.nvim/issues/424) ([9ddfd47](https://github.com/folke/trouble.nvim/commit/9ddfd47eec3a1bd43f5e7dd34eb1084f6793eaba))
* **statusline:** make sure max_items is honored ([da8ba7d](https://github.com/folke/trouble.nvim/commit/da8ba7dfba2341c5ea679e6cff85c01943777380))
* **statusline:** schedule statusline refresh ([f000daa](https://github.com/folke/trouble.nvim/commit/f000daadd6d49b30eebacb2a6dd7c4d9758f2de6))
* **telescope:** close telescope after sending results to trouble ([2753932](https://github.com/folke/trouble.nvim/commit/2753932bed13cff73be80e2565043dccce899983))
* **telescope:** deprecation warning for old telescope provider ([0d7cdeb](https://github.com/folke/trouble.nvim/commit/0d7cdeba2d139f26314d53e2e06507b6a7b72e3b))
* **throttle:** fixed throttling so that it now only gets scheduled when there are pending args ([0db2084](https://github.com/folke/trouble.nvim/commit/0db20847636e6715cb2d1c542fee34d349f47ee3))
* **tree:** fixed tree item count. Fixes [#419](https://github.com/folke/trouble.nvim/issues/419) ([cb59440](https://github.com/folke/trouble.nvim/commit/cb594402cf4407bbf54111c20ef39d42d9b017f6))
* **tree:** make sure qf items always have a unique id. Fixes [#367](https://github.com/folke/trouble.nvim/issues/367) ([c0755d5](https://github.com/folke/trouble.nvim/commit/c0755d59731869994187b04adcb89ebce75c27eb))
* **treesitter:** show warning for missing treesitter parsers ([4253652](https://github.com/folke/trouble.nvim/commit/425365272136c731eea9da4c337f7b1dfe4d44d6))
* **tree:** use format as node id for group without fields ([a29c293](https://github.com/folke/trouble.nvim/commit/a29c29382da0dcb8554da25e40a4d2495dff771f))
* **ui:** better deal with invalid items positions and extmarks. Fixes [#404](https://github.com/folke/trouble.nvim/issues/404) ([bc0a194](https://github.com/folke/trouble.nvim/commit/bc0a19482ee8f68eb427939df2e28cca800b9cbb))
* **util:** deprecation warnings for tbl_islist ([7577f3a](https://github.com/folke/trouble.nvim/commit/7577f3a82ff60ef7425451b1f40dd83ffee12307))
* **util:** typo ([37f6266](https://github.com/folke/trouble.nvim/commit/37f62665dfc8db002f7fe62ae6b467c566329ec3))
* **util:** use xpcall in throttle for better stack traces ([6d9a0ba](https://github.com/folke/trouble.nvim/commit/6d9a0baeb226548b967329d7c045c38ff16a19e8))
* **view:** check if trouble win is still valid in OptionSet. Fixes [#400](https://github.com/folke/trouble.nvim/issues/400) ([e9fae8c](https://github.com/folke/trouble.nvim/commit/e9fae8c453eac69aa33dc4899c46b76417a04e3e))
* **view:** check that window is open before checking active item ([5b5446d](https://github.com/folke/trouble.nvim/commit/5b5446ddf2d6c50b555d28459ce7632ca39d6ac0))
* **view:** do `norm! zz zv` after jump. See [#408](https://github.com/folke/trouble.nvim/issues/408) ([74e31e7](https://github.com/folke/trouble.nvim/commit/74e31e732fa6888a72f6b73b3115b8ea84ef47f5))
* **view:** dont refresh items when calling `open` and already open ([7485aa7](https://github.com/folke/trouble.nvim/commit/7485aa70e0341c55bd25e2287b29e991c61297d1))
* **view:** dont trigger follow when moving. Fixes [#3359](https://github.com/folke/trouble.nvim/issues/3359) ([7cc4df2](https://github.com/folke/trouble.nvim/commit/7cc4df259b208a1f19a67a171da7d5f7e917e7c4))
* **view:** store restore locations when moving the cursor. See [#367](https://github.com/folke/trouble.nvim/issues/367) ([d8265a6](https://github.com/folke/trouble.nvim/commit/d8265a6f0eea8fff249decf3a1304991f850715b))
* **window:** main window float should have regular winhighlight ([6ccd579](https://github.com/folke/trouble.nvim/commit/6ccd579a177dc81d81706194131e23b24e93e5fa))
* **window:** properly deal with alien buffers opening in trouble windows ([92832c4](https://github.com/folke/trouble.nvim/commit/92832c4676e079c4fe824fd5c9a5ba3259d2e506))
* **windows:** Corrected regex matching path with backslash. ([#396](https://github.com/folke/trouble.nvim/issues/396)) ([a784506](https://github.com/folke/trouble.nvim/commit/a784506b4e5f649e568ec6763aa90d7a7ec4c0b3))
* **window:** set cursorlineopt for the trouble window. Fixes [#356](https://github.com/folke/trouble.nvim/issues/356) ([4c07228](https://github.com/folke/trouble.nvim/commit/4c07228dec2663d9dda9b12f68785a9f9ec9fd72))


### Performance Improvements

* better throttle ([c10d53d](https://github.com/folke/trouble.nvim/commit/c10d53d3d7a48dc8090e44f375d2a12ca7ef0fb6))
* only trigger refresh when event happens in main for some sources ([6eac568](https://github.com/folke/trouble.nvim/commit/6eac5689fe59fbb8038eebb150c66dbb2a3960a0))
* use weak references to prevent memory leaks ([4d31d77](https://github.com/folke/trouble.nvim/commit/4d31d77561860cbe582239ebb970db1c75872018))
* **util:** get_lines can now use a buf or filename or both ([e987642](https://github.com/folke/trouble.nvim/commit/e9876428329f2a91e5dd8b29bd854d9b9ff7813a))

## [2.10.0](https://github.com/folke/trouble.nvim/compare/v2.9.1...v2.10.0) (2023-10-18)


### Features

* `open({focus=false})` now works as intended ([600fe24](https://github.com/folke/trouble.nvim/commit/600fe24ad04f130030fa54f0c70949ff084810a3))


### Bug Fixes

* **auto_open:** dont steal focus on auto open. Fixes [#344](https://github.com/folke/trouble.nvim/issues/344) ([1f00b6f](https://github.com/folke/trouble.nvim/commit/1f00b6f730c5ef6bcfeb829a5659ed3780778087))

## [2.9.1](https://github.com/folke/trouble.nvim/compare/v2.9.0...v2.9.1) (2023-10-09)


### Bug Fixes

* **preview:** skip non-existing. Fixes [#87](https://github.com/folke/trouble.nvim/issues/87). Fixes [#188](https://github.com/folke/trouble.nvim/issues/188). Fixes [#336](https://github.com/folke/trouble.nvim/issues/336). ([#338](https://github.com/folke/trouble.nvim/issues/338)) ([5e78824](https://github.com/folke/trouble.nvim/commit/5e7882429ee2e235148ab759a6159950afd8021a))

## [2.9.0](https://github.com/folke/trouble.nvim/compare/v2.8.0...v2.9.0) (2023-10-07)


### Features

* Make floating window configuration customizable ([#310](https://github.com/folke/trouble.nvim/issues/310)) ([ef0336a](https://github.com/folke/trouble.nvim/commit/ef0336a818e562439e25638b866cb4638a0fdc26))


### Bug Fixes

* check that view is valid before render and focus ([#319](https://github.com/folke/trouble.nvim/issues/319)) ([81e1643](https://github.com/folke/trouble.nvim/commit/81e1643a7c6b426535cf23ebdb28baec4ab7428e))
* only filter msg if sev is hardcoded ([#328](https://github.com/folke/trouble.nvim/issues/328)) ([0ccc43d](https://github.com/folke/trouble.nvim/commit/0ccc43d61e0f9278056a8eeefbe022ce71707a85))
* **qf:** properly deal with invalid qf entries. Fixes [#87](https://github.com/folke/trouble.nvim/issues/87). Fixes [#188](https://github.com/folke/trouble.nvim/issues/188). Fixes [#336](https://github.com/folke/trouble.nvim/issues/336) ([46b60e9](https://github.com/folke/trouble.nvim/commit/46b60e9fb942d60740c647f61fd779f05e7b9392))

## [2.8.0](https://github.com/folke/trouble.nvim/compare/v2.7.0...v2.8.0) (2023-07-25)


### Features

* Create Configuration for IncludeDeclaration ([#312](https://github.com/folke/trouble.nvim/issues/312)) ([7691d93](https://github.com/folke/trouble.nvim/commit/7691d93131be9c4ef7788892a9c52374642beb89))

## [2.7.0](https://github.com/folke/trouble.nvim/compare/v2.6.0...v2.7.0) (2023-07-25)


### Features

* Expose help action ([#311](https://github.com/folke/trouble.nvim/issues/311)) ([467dc20](https://github.com/folke/trouble.nvim/commit/467dc204af863a9f11bc3444b8f89af286fbf6b2))
* Use code descriptions for opening URIs with extra information ([#309](https://github.com/folke/trouble.nvim/issues/309)) ([d2b0f1d](https://github.com/folke/trouble.nvim/commit/d2b0f1de1fe6f013d38234f7557c7935a9f97655))

## [2.6.0](https://github.com/folke/trouble.nvim/compare/v2.5.0...v2.6.0) (2023-07-22)


### Features

* make multiline the default ([1f2eb71](https://github.com/folke/trouble.nvim/commit/1f2eb71948b8d08cd8fe0947f9dae95c441baf6d))

## [2.5.0](https://github.com/folke/trouble.nvim/compare/v2.4.0...v2.5.0) (2023-07-22)


### Features

* add multiline diagnostic support ([#305](https://github.com/folke/trouble.nvim/issues/305)) ([7a6abd7](https://github.com/folke/trouble.nvim/commit/7a6abd7ed811def9494316d4217d1dcc80b05048))
* Map double click to jump action ([#158](https://github.com/folke/trouble.nvim/issues/158)) ([ef53b9a](https://github.com/folke/trouble.nvim/commit/ef53b9a1401919a9a3ae5b2949068c456ce23085))
* use markdown to render hover ([835b87d](https://github.com/folke/trouble.nvim/commit/835b87d93537a3cc403b961c084ca8c2998758cd))
* **util:** trigger TroubleJump on jump. Closes [#248](https://github.com/folke/trouble.nvim/issues/248) ([d91f3b3](https://github.com/folke/trouble.nvim/commit/d91f3b3d588b0259060780c73dd4c93a8f158f38))

## [2.4.0](https://github.com/folke/trouble.nvim/compare/v2.3.0...v2.4.0) (2023-07-16)


### Features

* add option to control cycling of result list ([#302](https://github.com/folke/trouble.nvim/issues/302)) ([e7805dc](https://github.com/folke/trouble.nvim/commit/e7805dc3448f28599e022dc7a0e58060dfdeeb9a))
* rendering messages from provider ([#304](https://github.com/folke/trouble.nvim/issues/304)) ([a66a78b](https://github.com/folke/trouble.nvim/commit/a66a78b8878780e3b3154e9812ff040ec9b0f1d6))


### Bug Fixes

* Check parent window is valid before setting active ([#291](https://github.com/folke/trouble.nvim/issues/291)) ([c14786d](https://github.com/folke/trouble.nvim/commit/c14786d5e88f3e66360c70bab56694abd0e60af6))
* move end of doc pos to last line. Fixes [#151](https://github.com/folke/trouble.nvim/issues/151) ([cb4da04](https://github.com/folke/trouble.nvim/commit/cb4da0401abe7ae6f368bf79d2ed6c2571b1e7ba))

## [2.3.0](https://github.com/folke/trouble.nvim/compare/v2.2.3...v2.3.0) (2023-05-25)


### Features

* filter diagnostics by severity level ([#285](https://github.com/folke/trouble.nvim/issues/285)) ([b1f607f](https://github.com/folke/trouble.nvim/commit/b1f607ff0f2c107faf8b0c26d09877028b549d63))

## [2.2.3](https://github.com/folke/trouble.nvim/compare/v2.2.2...v2.2.3) (2023-05-22)


### Bug Fixes

* set window options locally ([#282](https://github.com/folke/trouble.nvim/issues/282)) ([a5649c9](https://github.com/folke/trouble.nvim/commit/a5649c9a60d7c5aa2fed1781057af3f29b10f167))

## [2.2.2](https://github.com/folke/trouble.nvim/compare/v2.2.1...v2.2.2) (2023-04-17)


### Bug Fixes

* **util:** auto_jump when trouble is open. Fixes [#144](https://github.com/folke/trouble.nvim/issues/144) ([e4f1623](https://github.com/folke/trouble.nvim/commit/e4f1623b51e18eb4e2835446e50886062c339f80))
* **util:** save position in jump list before jump. Fixes [#143](https://github.com/folke/trouble.nvim/issues/143) Fixes [#235](https://github.com/folke/trouble.nvim/issues/235) ([f0477b0](https://github.com/folke/trouble.nvim/commit/f0477b0e78d9a16ff326e356235876ff3f87882d))

## [2.2.1](https://github.com/folke/trouble.nvim/compare/v2.2.0...v2.2.1) (2023-03-26)


### Bug Fixes

* **icons:** fixed deprecated icons with nerdfix ([39db399](https://github.com/folke/trouble.nvim/commit/39db3994c8de87b0b5ca7a4d3d415926f201f1fc))

## [2.2.0](https://github.com/folke/trouble.nvim/compare/v2.1.1...v2.2.0) (2023-02-28)


### Features

* enable looping during next/prev ([#232](https://github.com/folke/trouble.nvim/issues/232)) ([fc4c0f8](https://github.com/folke/trouble.nvim/commit/fc4c0f82c9181f3c27a4cbdd5db97c110fd78ee9))
* expose renderer.signs. Fixes [#252](https://github.com/folke/trouble.nvim/issues/252) ([5581e73](https://github.com/folke/trouble.nvim/commit/5581e736c8afc8b227ad958ded1929c8a39f049e))

## [2.1.1](https://github.com/folke/trouble.nvim/compare/v2.1.0...v2.1.1) (2023-02-19)


### Bug Fixes

* ensure that the diagnostic parameters are complete ([#179](https://github.com/folke/trouble.nvim/issues/179)) ([210969f](https://github.com/folke/trouble.nvim/commit/210969fce79e7d11554c61bca263d7e1ac77bde0))
* icorrect row/line in diagnostics. Fixes [#264](https://github.com/folke/trouble.nvim/issues/264) ([32fa4ed](https://github.com/folke/trouble.nvim/commit/32fa4ed742fc91f3075c98edd3c131b716b9d782))

## [2.1.0](https://github.com/folke/trouble.nvim/compare/v2.0.1...v2.1.0) (2023-02-18)


### Features

* expose `require("trouble").is_open()` ([2eb27b3](https://github.com/folke/trouble.nvim/commit/2eb27b34442894e903fdc6e01edea6d7c476be63))

## [2.0.1](https://github.com/folke/trouble.nvim/compare/v2.0.0...v2.0.1) (2023-02-16)


### Bug Fixes

* **init:** version check ([73eea32](https://github.com/folke/trouble.nvim/commit/73eea32efec2056cdce7593787390fc9aadf9c0c))

## [2.0.0](https://github.com/folke/trouble.nvim/compare/v1.0.2...v2.0.0) (2023-02-16)


### ⚠ BREAKING CHANGES

* Trouble now requires Neovim >= 0.7.2

### Features

* Trouble now requires Neovim &gt;= 0.7.2 ([ef93259](https://github.com/folke/trouble.nvim/commit/ef9325970b341d436f43c50ce876aa0a665d3cf0))


### Bug Fixes

* Focus parent before closing ([#259](https://github.com/folke/trouble.nvim/issues/259)) ([66b057b](https://github.com/folke/trouble.nvim/commit/66b057b2b07881bceb969624f4c3b5727703c2c8))
* **preview:** properly load buffer when showing preview ([949199a](https://github.com/folke/trouble.nvim/commit/949199a9ac60ce784a417f90388b8f173ef53819))
* **util:** properly load a buffer when jumping to it ([bf0eeea](https://github.com/folke/trouble.nvim/commit/bf0eeead88d59d51003f4da1b649b4977ed90e2b))


### Performance Improvements

* dont load buffers when processing items. Get line with luv instead ([82c9a9a](https://github.com/folke/trouble.nvim/commit/82c9a9a9cd2cd2cdb05e05a3e6538529e2473e14))

## [1.0.2](https://github.com/folke/trouble.nvim/compare/v1.0.1...v1.0.2) (2023-02-10)


### Bug Fixes

* **telescope:** properly fix issue with relative filenames in telescope. See [#250](https://github.com/folke/trouble.nvim/issues/250) ([7da0821](https://github.com/folke/trouble.nvim/commit/7da0821d20342751a7eedecd28cf16040146cbf7))

## [1.0.1](https://github.com/folke/trouble.nvim/compare/v1.0.0...v1.0.1) (2023-01-23)


### Bug Fixes

* ensure first line is selected when padding is false ([#233](https://github.com/folke/trouble.nvim/issues/233)) ([b2d6ac8](https://github.com/folke/trouble.nvim/commit/b2d6ac8607e1ab612a85c1ec563aaff3a60f0603))
* **telescope:** correctly use cwd for files. Fixes [#250](https://github.com/folke/trouble.nvim/issues/250) ([3174767](https://github.com/folke/trouble.nvim/commit/3174767c61b3786e65d78f539c60c6f70d26cdbe))

## 1.0.0 (2023-01-04)


### ⚠ BREAKING CHANGES

* renamed use_lsp_diagnostic_signs to use_diagnostic_signs
* removed deprecated commands

### Features

* added "hover" action that defaults to "K" to show the full multiline text [#11](https://github.com/folke/trouble.nvim/issues/11) ([9111a5e](https://github.com/folke/trouble.nvim/commit/9111a5eb7881a84cd66107077118614e218fba61))
* added actions for opening in new tab, split and vsplit. Fixes [#36](https://github.com/folke/trouble.nvim/issues/36) ([c94cc59](https://github.com/folke/trouble.nvim/commit/c94cc599badb7086878559653ec705ed68579682))
* added mapping for jump & close (defaults to "o") [#15](https://github.com/folke/trouble.nvim/issues/15) ([09de784](https://github.com/folke/trouble.nvim/commit/09de78495bad194b2d0d85498a1c1a7996182a71))
* added support for vim.diagnostics and Neovim 0.7 ([735dcd5](https://github.com/folke/trouble.nvim/commit/735dcd599871179a835d1e0ebd777d4db24c2c72))
* allow proper passing of plugin options ([79513ed](https://github.com/folke/trouble.nvim/commit/79513ed42a273a1bc80d82c7e1117d3a2e0f2c79))
* Api to go to first and last items ([#157](https://github.com/folke/trouble.nvim/issues/157)) ([0649811](https://github.com/folke/trouble.nvim/commit/0649811e69a11dea4708a19deee9ab0b1e90313e))
* better preview and mode ([160fa6c](https://github.com/folke/trouble.nvim/commit/160fa6cb213db6c7a421450b67adc495ae69cef0))
* command complete ([9923b01](https://github.com/folke/trouble.nvim/commit/9923b01692a238535420d58e440b139a89c3de46))
* comments to open/toggle workspace or ducument mode directly ([f7db1c2](https://github.com/folke/trouble.nvim/commit/f7db1c29d7eb76cb3310e0aa56a4d546420e7814))
* config for auto_preview ([0ad97fb](https://github.com/folke/trouble.nvim/commit/0ad97fb67b21579729090214cbb3bce78fd153b7))
* define multiple keybindings for the same action (better for defaults) ([bf8e8ee](https://github.com/folke/trouble.nvim/commit/bf8e8ee63c38103fb42de0b889810b584e378962))
* expose items ([#41](https://github.com/folke/trouble.nvim/issues/41)) ([4f84ca4](https://github.com/folke/trouble.nvim/commit/4f84ca4530829b9448c6f13530c26df6d7020fd0))
* indent lines ([f9e6930](https://github.com/folke/trouble.nvim/commit/f9e6930b5188593b9e6408d8937093d04198e90a))
* inital version ([980fb07](https://github.com/folke/trouble.nvim/commit/980fb07fd33ea0f72b274e1ad3c8626bf8a14ac9))
* Lsp implementation ([#50](https://github.com/folke/trouble.nvim/issues/50)) ([069cdae](https://github.com/folke/trouble.nvim/commit/069cdae61d58d2477b150af91692ace636000d47))
* lsp references, loclist and quickfix lists! ([0b852c8](https://github.com/folke/trouble.nvim/commit/0b852c8418d65191983b2c9b8f90ad6d7f45ff51))
* made it easier to integrate with trouble ([1dd72c2](https://github.com/folke/trouble.nvim/commit/1dd72c22403519c160b0c694762091971bcf191e))
* make file grouping and padding configurable ([#66](https://github.com/folke/trouble.nvim/issues/66)) ([ff40475](https://github.com/folke/trouble.nvim/commit/ff40475143ecd40c86f13054935f3afc5653c469))
* make position of the trouble list configurable (top, bottom, left or right) [#27](https://github.com/folke/trouble.nvim/issues/27) ([0c9ca5e](https://github.com/folke/trouble.nvim/commit/0c9ca5e10c2e5dd8d8479e864e12383b1d614273))
* make signs configurable ([ff9fd51](https://github.com/folke/trouble.nvim/commit/ff9fd51ab05398c83c2a0b384999d49269d95572))
* make sorting keys configurable ([#190](https://github.com/folke/trouble.nvim/issues/190)) ([68d3dc5](https://github.com/folke/trouble.nvim/commit/68d3dc52fe49375fe556af69d1e91e0a88b67935))
* next/previous API. Implements [#44](https://github.com/folke/trouble.nvim/issues/44) ([a2a7dbf](https://github.com/folke/trouble.nvim/commit/a2a7dbfefc5ebdf1a9c1d37e9df1d26a3b13c1cd))
* option to automatically jump when there is only one result (fixes [#57](https://github.com/folke/trouble.nvim/issues/57)) ([#79](https://github.com/folke/trouble.nvim/issues/79)) ([09fafb2](https://github.com/folke/trouble.nvim/commit/09fafb2e01fbaa4fe6ecede10a7e7a738464deba))
* **providers.lsp:** Add definitions support  ([#20](https://github.com/folke/trouble.nvim/issues/20)) ([a951198](https://github.com/folke/trouble.nvim/commit/a95119893c8dfd4b4bed42da97d601c25c7a495f))
* sort files by current directory and prefer non-hidden ([ea9a5e3](https://github.com/folke/trouble.nvim/commit/ea9a5e331b70cf4011081c951015033f0079a0cc))
* sort items by severity / filename / lnum / col ([4a45782](https://github.com/folke/trouble.nvim/commit/4a45782db943f95500b61ffce187bf4cada954ae))
* sort results by row and column isntead of just row ([#118](https://github.com/folke/trouble.nvim/issues/118)) ([5897b09](https://github.com/folke/trouble.nvim/commit/5897b09933731298382e86a5cf4d1a4861630873))
* **telescope provider:** (Smart) multiselect ([#39](https://github.com/folke/trouble.nvim/issues/39)) ([45ff198](https://github.com/folke/trouble.nvim/commit/45ff198f4d436d256f02b14db9c817024c7fc85c))
* Telescope support ([9c81e16](https://github.com/folke/trouble.nvim/commit/9c81e16adec697ffd0b694eb86e14cfee453917d))
* use vim.notify for logging ([293118e](https://github.com/folke/trouble.nvim/commit/293118e195639c373a6a744621b9341e5e18f6e4))


### Bug Fixes

* Add nowait option to keymap ([#30](https://github.com/folke/trouble.nvim/issues/30)) ([4375f1f](https://github.com/folke/trouble.nvim/commit/4375f1f0b2457fcbb91d32de457e6e3b3bb7eba7))
* added additional space between message and code ([aae12e7](https://github.com/folke/trouble.nvim/commit/aae12e7b23b3a2b8337ec5b1d6b7b4317aa3929b))
* added compatibility to retrieve signs from vim.diagnostic ([dab82ef](https://github.com/folke/trouble.nvim/commit/dab82ef0f39893f50908881fdc5e96bfb1578ba1))
* added suport for vim.diagnostic hl groups ([d25a8e6](https://github.com/folke/trouble.nvim/commit/d25a8e6779462127fb227397fa92b07bced8a6fe))
* added support for new handler signatures (backward compatible with 0.5) ([87cae94](https://github.com/folke/trouble.nvim/commit/87cae946aee4798bee621ea6108224c08c218d69))
* auto_open was broken. Fixed now [#29](https://github.com/folke/trouble.nvim/issues/29) ([a2f2b92](https://github.com/folke/trouble.nvim/commit/a2f2b9248bed41522d8caa3a7e9932981c4087ec))
* better detection of the parent window ([4c5fd8a](https://github.com/folke/trouble.nvim/commit/4c5fd8abaf6058312ebe52f662ca002bf0aa9f77))
* default to current window in jump_to_item ([#175](https://github.com/folke/trouble.nvim/issues/175)) ([ec24219](https://github.com/folke/trouble.nvim/commit/ec242197b1f72cabe17dfd61119c896f58bda672))
* don't "edit" en existing buffer. Use "buffer" instead. ([#5](https://github.com/folke/trouble.nvim/issues/5), [#6](https://github.com/folke/trouble.nvim/issues/6)) ([abef115](https://github.com/folke/trouble.nvim/commit/abef1158c0ff236333f67f9f091e5d9ae67d6a89))
* don't steal focus on auto_open. Fixes [#48](https://github.com/folke/trouble.nvim/issues/48) ([36b6813](https://github.com/folke/trouble.nvim/commit/36b6813a2103d85b469a61721b030903ddd8b3b3))
* don't try to fetch sign for "other" ([5b50990](https://github.com/folke/trouble.nvim/commit/5b509904f8865bea7d09b7a686e139077a2484c6))
* don't use file sorter for items without a valid filename ([20469be](https://github.com/folke/trouble.nvim/commit/20469be985143d024c460d95326ebeff9971d714))
* dont advance two items at a time. Fixes https://github.com/folke/todo-comments.nvim/issues/39 ([7de8bc4](https://github.com/folke/trouble.nvim/commit/7de8bc46164ec1f787dee34b6843b61251b1ea91))
* files without col/row should be set to col=1 and row=1 [#22](https://github.com/folke/trouble.nvim/issues/22) ([fcd5f1f](https://github.com/folke/trouble.nvim/commit/fcd5f1fc035ee3d9832c63a307247c09f25c9cd1))
* filetype set too early ([#230](https://github.com/folke/trouble.nvim/issues/230)) ([c4da921](https://github.com/folke/trouble.nvim/commit/c4da921ba613aa6d6659dc18edc204c37e4b8833))
* fixed auto_open swicth_to_parent. Fixes [#7](https://github.com/folke/trouble.nvim/issues/7) ([7cf1aa1](https://github.com/folke/trouble.nvim/commit/7cf1aa1195245d3098097bc3a2510dc358c87363))
* give focus back to correct window when closing ([#72](https://github.com/folke/trouble.nvim/issues/72)) ([a736b8d](https://github.com/folke/trouble.nvim/commit/a736b8db9f49b8b49ac96fbab7f8e396032cfa37))
* handle normal api calls to trouble as it should [#42](https://github.com/folke/trouble.nvim/issues/42) ([52b875d](https://github.com/folke/trouble.nvim/commit/52b875d1aaf88f32e9f070a0119190c3e65b51a5))
* if grouping is off, decrease indent ([#140](https://github.com/folke/trouble.nvim/issues/140)) ([ed65f84](https://github.com/folke/trouble.nvim/commit/ed65f84abc4a1e5d8f368d7e02601fc0357ea15e))
* lazy include telescope when needed ([7e3d4f9](https://github.com/folke/trouble.nvim/commit/7e3d4f9efc157bbfeb3e37837f8ded9289c48f25))
* lsp diag creates ugly buffers for unopened files in the workspace. Fixed now ([91d1139](https://github.com/folke/trouble.nvim/commit/91d1139d85407b99bd4d2f6850200a793631679b))
* lsp diagnostics codes ([dbbd523](https://github.com/folke/trouble.nvim/commit/dbbd523d91fe51e8421909147bf069b1ec780720))
* lsp handler error log ([#95](https://github.com/folke/trouble.nvim/issues/95)) ([063aefd](https://github.com/folke/trouble.nvim/commit/063aefd69a8146e27cde860c9ddd807891e5a119))
* **lsp:** avoid overwriting uri of result ([#60](https://github.com/folke/trouble.nvim/issues/60)) ([655391c](https://github.com/folke/trouble.nvim/commit/655391c2f592ef61943b6325030333dfacc54757))
* only use old hl groups when they exist (Fixes [#49](https://github.com/folke/trouble.nvim/issues/49)) ([d4ce76f](https://github.com/folke/trouble.nvim/commit/d4ce76fa82cdbd12dcf9dbfa682dae89b2a143ac))
* possible vim.NIL on diagnostics code ([1faa347](https://github.com/folke/trouble.nvim/commit/1faa347a93748531b5e418d84276c93da21b86a7))
* prevent segfault on closing ([756f09d](https://github.com/folke/trouble.nvim/commit/756f09de113a775ab16ba6d26c090616b40a999d))
* properly close trouble window on close ([d10ee4b](https://github.com/folke/trouble.nvim/commit/d10ee4bc99b8e2bb842c2274316db400b197cca9))
* properly exit when trouble is the last window. Fixes [#24](https://github.com/folke/trouble.nvim/issues/24) ([2b27b96](https://github.com/folke/trouble.nvim/commit/2b27b96c7893ac534ba0cbfc95d52c6c609a0b20))
* remove useless "no results" notification ([#164](https://github.com/folke/trouble.nvim/issues/164)) ([da61737](https://github.com/folke/trouble.nvim/commit/da61737d860ddc12f78e638152834487eabf0ee5)), closes [#154](https://github.com/folke/trouble.nvim/issues/154)
* removed space betweend rendering of source + code ([b676029](https://github.com/folke/trouble.nvim/commit/b6760291874d078668f4ff04d78acc0670536ca9))
* removed unused plenary require. Fixes [#1](https://github.com/folke/trouble.nvim/issues/1) ([1ff45e2](https://github.com/folke/trouble.nvim/commit/1ff45e274de32e816b891b1ca12f73f73b58a604))
* replace possible newlines in rendered text ([08d068f](https://github.com/folke/trouble.nvim/commit/08d068fb1668b7f898af721cbc8a1ae72ddf6565))
* restore item indentation ([7c93271](https://github.com/folke/trouble.nvim/commit/7c93271e7a6a147b8f4342f5b377fa863419846f))
* set buftype before filetype ([#67](https://github.com/folke/trouble.nvim/issues/67)) ([169b2ec](https://github.com/folke/trouble.nvim/commit/169b2ec3a4d0cac01f22cc8f7332f1d0a11f1fa4))
* set EndOfBuffer to LspTroubleNormal and hide ~ [#23](https://github.com/folke/trouble.nvim/issues/23) ([7d67f34](https://github.com/folke/trouble.nvim/commit/7d67f34d92b3b52ca63c84f929751d98b3f56b63))
* set nowrap for the trouble window. Fixes [#69](https://github.com/folke/trouble.nvim/issues/69) ([51dd917](https://github.com/folke/trouble.nvim/commit/51dd9175eb506b026189c70f81823dfa77defe86))
* set the filetype lastly so autocmd's can override options from it ([#126](https://github.com/folke/trouble.nvim/issues/126)) ([b5353dd](https://github.com/folke/trouble.nvim/commit/b5353ddcd09bd7e93d6f934149d25792d455a8fb))
* show warning when icons=true but devicons is not installed ([7aabea5](https://github.com/folke/trouble.nvim/commit/7aabea5cca2d51ba5432c988fe84ff9d3644637a))
* support LocationLink ([#94](https://github.com/folke/trouble.nvim/issues/94)) ([7f3761b](https://github.com/folke/trouble.nvim/commit/7f3761b6dbadd682a20bd1ff4cb588985c14c9a0))
* typos ([#55](https://github.com/folke/trouble.nvim/issues/55)) ([059ea2b](https://github.com/folke/trouble.nvim/commit/059ea2b999171f50019291ee776dd496799fdf3a))
* use deprecated vim.lsp.diagnostics for now ([afb300f](https://github.com/folke/trouble.nvim/commit/afb300f18c09f7b474783aa12eb680ea59785b46))
* use new DiagnosticChanged event ([#127](https://github.com/folke/trouble.nvim/issues/127)) ([4d0a711](https://github.com/folke/trouble.nvim/commit/4d0a711e7432eed022611ce385f3a7714e81f63b)), closes [#122](https://github.com/folke/trouble.nvim/issues/122)
* use vim.diagnostic instead of vim.lsp.diagnostic when available ([a2e2e7b](https://github.com/folke/trouble.nvim/commit/a2e2e7b53f389f84477a1a11c086c9a379af702e))
* workspace and document diagnostics were switched around ([1fa8469](https://github.com/folke/trouble.nvim/commit/1fa84691236d16a2d1c12707c1fbc54060c910f7))


### Performance Improvements

* debounce auto refresh when diagnostics get updated ([068476d](https://github.com/folke/trouble.nvim/commit/068476db8576e5b32acf20df040e7fca032cd11d))
* much faster async preview ([2c9b319](https://github.com/folke/trouble.nvim/commit/2c9b3195a7fa8cfc19a368666c9f83fd7a20a482))
* only fetch line when needed. Fixes [#26](https://github.com/folke/trouble.nvim/issues/26) ([52f18fd](https://github.com/folke/trouble.nvim/commit/52f18fd6bea57af54265247a3ec39f19a31adce3))
* only update diagnostics once when window changes ([d965d22](https://github.com/folke/trouble.nvim/commit/d965d22ee37e50be0ab32f6a5987a8cd88206f10))
* prevent nested loading of preview [#2](https://github.com/folke/trouble.nvim/issues/2) ([b20a784](https://github.com/folke/trouble.nvim/commit/b20a7844a035cf6795270db575ad8c4db2a774c9))
* use vim.lsp.util.get_line to get line instad of bufload ([607b1d5](https://github.com/folke/trouble.nvim/commit/607b1d5bbfdbd19242659415746b5e62f5ddfb94))


### Code Refactoring

* removed deprecated commands ([dd89ad9](https://github.com/folke/trouble.nvim/commit/dd89ad9ebb63e131098ff04857f8598eb88d8d79))
* renamed use_lsp_diagnostic_signs to use_diagnostic_signs ([9db77e1](https://github.com/folke/trouble.nvim/commit/9db77e194d848744139673aa246efa00fbcba982))
