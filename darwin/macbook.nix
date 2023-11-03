#
#  Specific system configuration settings for MacBook
#
#  flake.nix
#   └─ ./darwin
#       ├─ default.nix
#       ├─ macbook.nix *
#       └─ ./modules
#           └─ default.nix
#

{ config, pkgs, vars, ... }:
let
  pythonPkgs = pkgs.python3Packages;
  fortlsFromSrc = import ./fortls.nix {
    inherit (pkgs) lib fetchFromGitHub; 
    inherit (pythonPkgs) buildPythonApplication setuptools-scm json5 packaging;
  };
  findentFromSrc = import ./findent.nix {
    inherit (pkgs) lib fetchFromGitHub stdenv;
  };
  asciidoctorFromSrc = import ./asciidoctor/asciidoctor.nix {
    inherit (pkgs) lib bundlerApp bundlerUpdateScript jre;
  };
  asciidoxyFromSrc = import ./asciidoxy.nix {
    inherit (pkgs) lib fetchPypi;
    inherit (pythonPkgs) buildPythonApplication json5 tqdm mako toml aiohttp pyparsing six;
  };
in
{
  imports = ( import ./modules );

  users.users.${vars.user} = {            # MacOS User
    home = "/Users/${vars.user}";
    shell = pkgs.zsh;                     # Default Shell
  };

  networking = {
    computerName = "MacBook";             # Host Name
    hostName = "MacBook";
  };

  skhd.enable = false;                    # Window Manager
  yabai.enable = false;                   # Hotkeys

  fonts = {                               # Fonts
    fontDir.enable = true;
    fonts = with pkgs; [
      source-code-pro
      font-awesome
      (nerdfonts.override {
        fonts = [
          "FiraCode"
        ];
      })
    ];
  };

  environment = {
    shells = with pkgs; [ zsh ];          # Default Shell
    variables = {                         # Environment Variables
      EDITOR = "${vars.editor}";
      VISUAL = "${vars.editor}";
      JAVA_HOME = "${pkgs.openjdk.home}";
    };
    systemPackages = with pkgs; [         # System-Wide Packages
      # Terminal
      wget
      gettext
      ansible
      git
      pfetch
      ranger
      
      openjdk
      # Doom Emacs
      emacs
      fd
      ripgrep
      #fortls 尝试在本地构建
      fortlsFromSrc
      findentFromSrc
      asciidoctorFromSrc
      asciidoxyFromSrc 
       
      # add wjq
      doxygen
      poetry
    ];
  };

  programs = {
    zsh.enable = true;                    # Shell
  };

  services = {
    nix-daemon.enable = true;             # Auto-Upgrade Daemon
  };

  homebrew = {                            # Homebrew Package Manager
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
    brews = [
      "wireguard-tools"
    ];
    casks = [
      "moonlight"
      "plex-media-player"
    ];
  };

  nix = {
    package = pkgs.nix;
    gc = {                                # Garbage Collection
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      auto-optimise-store = true
      experimental-features = nix-command flakes
    '';
  };

  system = {                              # Global macOS System Settings
    defaults = {
      NSGlobalDomain = {
        KeyRepeat = 1;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
      };
      dock = {
        autohide = true;
        orientation = "bottom";
        showhidden = true;
        tilesize = 40;
      };
      finder = {
        QuitMenuItem = false;
      };
      trackpad = {
        Clicking = true;
        TrackpadRightClick = true;
      };
    };
    activationScripts.postActivation.text = ''sudo chsh -s ${pkgs.zsh}/bin/zsh''; # Set Default Shell
    stateVersion = 4;
  };

  home-manager.users.${vars.user} = {
    home = {
      stateVersion = "22.05";
    };

    programs = {
      zsh = {                             # Shell
        enable = true;
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        history.size = 10000;

        oh-my-zsh = {                     # Plug-ins
          enable = true;
          plugins = [ "git" ];
          custom = "$HOME/.config/zsh_nix/custom";
        };

        initExtra = ''
          # Spaceship
          source ${pkgs.spaceship-prompt}/share/zsh/site-functions/prompt_spaceship_setup
          autoload -U promptinit; promptinit
          pfetch
        '';                               # Theming
      };
      neovim = {
        enable = true;
        viAlias = true;
        vimAlias = true;

        plugins = with pkgs.vimPlugins; [
          # Syntax
          vim-nix
          vim-markdown
          vim-markdown-composer
          # Quality of life
          vim-lastplace                   # Opens document where you left it
          auto-pairs                      # Print double quotes/brackets/etc.
          vim-gitgutter                   # See uncommitted changes of file :GitGutterEnable

          # File Tree
          nerdtree                        # File Manager - set in extraConfig to F6

          # Customization
          wombat256-vim                   # Color scheme for lightline
          srcery-vim                      # Color scheme for text

          lightline-vim                   # Info bar at bottom
          indent-blankline-nvim           # Indentation lines

          nvim-lspconfig
          nvim-dap
          nvim-dap-ui
        ];

        extraConfig = ''
          syntax enable                             " Syntax highlighting
          colorscheme srcery                        " Color scheme text
          let g:lightline = {
            \ 'colorscheme': 'wombat',
            \ }                                     " Color scheme lightline

          highlight Comment cterm=italic gui=italic " Comments become italic
          hi Normal guibg=NONE ctermbg=NONE         " Remove background, better for personal theme

          set number                                " Set numbers

          nmap <F6> :NERDTreeToggle<CR>             " F6 opens NERDTree

          " Language server configurations
          lua << EOF
          require'lspconfig'.fortls.setup{
            cmd = { "${pkgs.fortls}/bin/fortls" },  " Set the specific path of fortls"
          }

          local dap = require('dap')
          dap.adapters.python = {
            type = 'executable';
            command = 'python';
          args = { '-m', 'debugpy.adapter' };
          }

          dap.configurations.python = {
          {
          type = 'python';
          request = 'launch';
          name = "Launch file";
          program = function()
            return vim.fn.expand("%:p")  
          end;
          stopOnEntry = true;  -- 添加这一行
          console = 'integratedTerminal'; 
          pythonPath = function()
            local handle = io.popen("poetry env info -p")  
            local result = handle:read("*a")
            handle:close()
            return result:gsub("%s+", "") .. "/bin/python"  
          end,
          },
          {
          type = 'python';
          request = 'launch';
          name = "config";
          program = "codegpt";  -- The entry point of your program
          args = {"config"}; -- The arguments your program needs 
          -- stopOnEntry = true;  -- 添加这一行
          pythonPath = function()
            local handle = io.popen("poetry env info -p")  -- Execute poetry command
            local result = handle:read("*a")
            handle:close()
            return result:gsub("%s+", "") .. "/bin/python"  -- Append "/bin/python" to the path
          end,
          },
          }


          local dapui=require("dapui")
          dapui.setup()
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end


          EOF

        '';
      };
    };
  };
}
