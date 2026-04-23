# Telemetry opt-outs
#
# DO_NOT_TRACK is a cross-tool convention (https://consoledonottrack.com)
# honored by gh, mise, Deno, Netlify CLI, Astro, and many others.
export DO_NOT_TRACK=1

# Tools that ignore DO_NOT_TRACK and require their own env var:
export HOMEBREW_NO_ANALYTICS=1
export NEXT_TELEMETRY_DISABLED=1
export NUXT_TELEMETRY_DISABLED=1
export GATSBY_TELEMETRY_DISABLED=1
export ASTRO_TELEMETRY_DISABLED=1
export CHECKPOINT_DISABLE=1          # HashiCorp (Terraform, Packer, Vagrant)
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1
