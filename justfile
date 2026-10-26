set shell := ["powershell.exe", "-NoLogo", "-Command"]
set dotenv-load

# default to steam default game dir
DEFAULT_GAME_DIR := join("C:\\", "Program Files (x86)", "Steam", "steamapps", "common", "Cyberpunk 2077")

game_dir            := env("GAME_DIR", DEFAULT_GAME_DIR)
plugin_name         := 'loot_icons_extension_fix'
script_name         := 'LootIconsExtensionFix'

# codebase (here)
red4ext_bin_dir     := join(justfile_directory(), "target")
redscript_repo_dir  := join(justfile_directory(), "reds")

# game files
red4ext_deploy_dir    := join("red4ext", "plugins", plugin_name)
redscript_deploy_dir  := join("r6", "scripts", script_name)
red_cache_dir         := join("r6", "cache")

[private]
setup path:
  @if (!(Test-Path '{{path}}')) { [void](New-Item '{{path}}' -ItemType Directory); Write-Host "Created folder at {{path}}"; }

[private]
delete path:
  @if (Test-Path '{{path}}') { [void](Remove-Item -Force -Recurse '{{path}}'); Write-Host "Deleted folder at {{path}}"; }

[private]
copy from to:
  @Copy-Item -Force '{{from}}' '{{to}}'
  @Write-Host "Copied {{from}} -> {{to}}"

[private]
copy-recurse from to:
  @Copy-Item -Force -Recurse '{{from}}' '{{to}}'
  @Write-Host "Copied {{from}} -> {{to}}"

# 🕓 log current time
[private]
now:
  @Write-Host "$(Get-Date) $_"

# 📦 build Rust RED4Ext plugin
build PROFILE='debug' TO=game_dir: (setup (TO / red4ext_deploy_dir))
  @cargo build {{ if PROFILE == "release" { "--release" } else { "" } }}
  @just copy '{{ join(red4ext_bin_dir, PROFILE, plugin_name + ".dll") }}' '{{ join(TO, red4ext_deploy_dir, plugin_name + ".dll") }}'
  @just now

alias b := build

# 🧑‍💻 build & reload
dev: (build) reload

# 🧐 debug with CodeLLDB
lldb TO=game_dir: dev
  @just copy '{{ join(red4ext_bin_dir, "debug", plugin_name + ".pdb") }}' '{{ join(TO, red4ext_deploy_dir, plugin_name + ".pdb") }}'
  @just now

checksum IN OUT:
  Get-FileHash -Path "{{IN}}" -Algorithm SHA256 | Select-Object -ExpandProperty Hash > "{{OUT}}"

# 🤖 package in CI
ci TO: (setup (TO / red4ext_deploy_dir)) (setup (TO / redscript_deploy_dir)) (build 'release' TO) (reload TO)

# 🔥 clear cache
clear:
    @if(Test-Path "{{ join(red_cache_dir, 'final.redscripts.bk') }}" ) { \
        Write-Host "replacing {{ join(red_cache_dir, 'final.redscripts.bk') }} with {{ join(red_cache_dir, 'final.redscripts.bk') }}"; \
        cp -Force '{{ join(red_cache_dir, "final.redscripts.bk") }}' '{{ join(red_cache_dir, "final.redscripts") }}'; \
        Remove-Item -Force -Path '{{ join(red_cache_dir, "final.redscripts.bk") }}'; \
    } else { \
        Write-Host "missing {{ join(red_cache_dir, 'final.redscripts.bk') }}"; \
    }

# 🔄 overwrite Redscript file(s)
reload TO=game_dir: (setup (TO / redscript_deploy_dir))
  @just copy-recurse '{{ join(redscript_repo_dir, "*") }}' '{{ join(TO, redscript_deploy_dir) }}'
  @just now

alias r := reload

# 🗑️  uninstall mod
uninstall FROM=game_dir:
  just delete '{{ join(FROM, red4ext_deploy_dir) }}'
  just delete '{{ join(FROM, redscript_deploy_dir) }}'

# 📐 format code
format:
  @cargo fmt

# 🎨 lint code
@lint:
  cargo clippy --fix --allow-dirty --allow-staged
  cargo fix --allow-dirty --allow-staged
  just format

alias l := lint

# 🔷 quality insurance (format, lint, etc)
qa:
  @cargo clippy -- -D warnings
  @cargo fix
  @cargo fmt --check

# ✅ unit-tests
@test:
  echo 'TODO'; exit 0

alias t := test

# ☑️  compilation check
check:
  @cargo check --all

alias c := check

# 🗒️  documentation
@doc:
  cargo doc --open --no-deps --document-private-items
