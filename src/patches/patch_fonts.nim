## Patch for forcing a particular font on all text in the Roblox client
## Copyright (C) 2024 Trayambak Rai
import std/[os, logging, strutils]
import ../common

const SoberFontsPath* {.strdefine.} =
  "$1/.var/app/" & SOBER_APP_ID & "/data/sober/assets/content/fonts/"

proc setClientFont*(fontPath: string, exclude: seq[string]) =
  let basePath = SoberFontsPath % [getHomeDir()]
  if fontPath.len > 0:
    debug "lucem: patching client font to `" & fontPath & '`'
    if not fileExists(fontPath):
      error "lucem: cannot set client font to `" & fontPath & "`: file not found"
      return

    when defined(release):
      if fileExists(basePath / "lucem_patched") and
          readFile(basePath / "lucem_patched") == fontPath:
        debug "lucem: font patch is already applied, ignoring."
        return

    writeFile(basePath / "lucem_patched", fontPath)
    discard existsOrCreateDir(basePath / "old_roblox_fonts")
    var patched: int

    for kind, file in walkDir(basePath):
      if kind != pcFile:
        continue
      if file.contains("lucem_patched"):
        continue
      let splitted = file.splitFile()

      if file.splitPath().tail in exclude:
        info "lucem: font file \"" & file &
          "\" is in the exclusion list, not overriding it."
        continue

      moveFile(file, basePath / "old_roblox_fonts" / splitted.name & splitted.ext)
      copyFile(fontPath, file)
      inc patched
      debug "lucem: " & fontPath & " >> " & file

    info "lucem: patched " & $patched & " fonts successfully!"
  else:
    if not fileExists(basePath / "lucem_patched"):
      return

    debug "lucem: restoring client font to defaults"

    # clear out all patched fonts
    for kind, file in walkDir(basePath):
      if kind != pcFile:
        continue
      if not file.endsWith("otf") and not file.endsWith("ttf"):
        continue

      removeFile(file)

    debug "lucem: moving old fonts back to their place"

    if not dirExists(basePath / "old_roblox_fonts"):
      error "lucem: the old Roblox fonts were somehow deleted!"
      error "lucem: you probably messed something up, run `lucem init` to fix it up."
      quit(1)

    var restored: int
    for kind, file in walkDir(basePath / "old_roblox_fonts"):
      if kind != pcFile:
        continue
      let splitted = file.splitFile()

      debug "lucem: " & file & " >> " & basePath / splitted.name & splitted.ext
      moveFile(file, basePath / splitted.name & splitted.ext)

      inc restored

    removeFile(basePath / "lucem_patched")
    removeDir(basePath / "old_roblox_fonts")
    info "lucem: restored " & $restored & " fonts to their defaults!"
