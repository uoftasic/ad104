# probe.tcl - a back channel into a running Magic, for the screenshot rig.
#
# Sourced by Magic at startup (rig.sh's magic_open adds `source /rig/probe.tcl` to the
# .magicrc in the folder Magic starts in). Every 100 ms it looks for $RIG_PROBE_DIR/cmd;
# when one appears it evaluates the file's contents at global level and writes
# "<catch code>\n<result>" to $RIG_PROBE_DIR/out. rig.sh uses it to read state the screen
# only shows as pixels (box values, DRC counts, widget positions for menu items and palette
# buttons), and to wait for Magic to be ready. It never draws anything and never echoes
# into tkcon, so it does not show up in screenshots. Keep probe commands quiet:
# `box values`, not `box`.

namespace eval ::rigprobe {
    variable dir /tmp/rig
    if {[info exists ::env(RIG_PROBE_DIR)]} { set dir $::env(RIG_PROBE_DIR) }
    file mkdir $dir
}

proc ::rigprobe::poll {} {
    variable dir
    set f [file join $dir cmd]
    if {[file exists $f]} {
        set fh [open $f r]
        set cmd [read $fh]
        close $fh
        file delete $f
        # Handle X events that are already queued first: xdotool's pointer moves reach the
        # X server before the probe file is written, but Tk may run this timer before it
        # reads them, and `cursor` would then report the previous pointer position.
        update
        set rc [catch {uplevel #0 $cmd} res]
        set tmp [file join $dir out.tmp]
        set fh [open $tmp w]
        puts -nonewline $fh "$rc\n$res"
        close $fh
        file rename -force $tmp [file join $dir out]
    }
    after 100 ::rigprobe::poll
}

# Widget helpers, so a step file can click real Tk widgets by name instead of by pixel.

# rootxy WIDGET: centre of a widget in screen coordinates.
proc ::rigprobe::center {w} {
    update idletasks
    list [expr {[winfo rootx $w] + [winfo width $w] / 2}] \
         [expr {[winfo rooty $w] + [winfo height $w] / 2}]
}

# The layout frame of the first (or named) layout window.
proc ::rigprobe::frame {{win {}}} {
    if {$win eq {}} { set win [lindex [magic::windownames layout] 0] }
    set fr [winfo parent $win]
    if {[winfo exists ${fr}.pane.top]} { return ${fr}.pane.top }
    return $fr
}

# menubutton MENU: screen centre of the titlebar menubutton whose label is MENU
# (File, Edit, Cell, Window, Layers, Drc, Options, Devices 1, Devices 2...).
proc ::rigprobe::menubutton {label} {
    set fr [::rigprobe::frame]
    foreach mb [winfo children ${fr}.titlebar.mbuttons] {
        if {[winfo class $mb] eq "Menubutton" && [$mb cget -text] eq $label} {
            return [::rigprobe::center $mb]
        }
    }
    error "no menubutton \"$label\""
}

# menuitem MENU ITEM: screen position of an entry in a posted menu. The menu must be
# posted (clicked open) first, because Tk only maps a menu while it is posted.
proc ::rigprobe::menuitem {label item} {
    set fr [::rigprobe::frame]
    foreach mb [winfo children ${fr}.titlebar.mbuttons] {
        if {[winfo class $mb] eq "Menubutton" && [$mb cget -text] eq $label} {
            set m [$mb cget -menu]
            set last [$m index end]
            for {set i 0} {$i <= $last} {incr i} {
                if {[$m type $i] in {command checkbutton radiobutton cascade}
                        && [$m entrycget $i -label] eq $item} {
                    update idletasks
                    set y0 [$m yposition $i]
                    if {$i < $last} { set y1 [$m yposition [expr {$i + 1}]] } \
                        else { set y1 [winfo height $m] }
                    return [list [expr {[winfo rootx $m] + 30}] \
                                 [expr {[winfo rooty $m] + ($y0 + $y1) / 2}]]
                }
            }
            error "menu \"$label\" has no item \"$item\""
        }
    }
    error "no menubutton \"$label\""
}

# menuitems MENU: the labels in a titlebar menu, in order (separators as "---").
proc ::rigprobe::menuitems {label} {
    set fr [::rigprobe::frame]
    foreach mb [winfo children ${fr}.titlebar.mbuttons] {
        if {[winfo class $mb] eq "Menubutton" && [$mb cget -text] eq $label} {
            set m [$mb cget -menu]
            set out {}
            for {set i 0} {$i <= [$m index end]} {incr i} {
                if {[$m type $i] eq "separator"} { lappend out --- } \
                    else { lappend out [$m entrycget $i -label] }
            }
            return $out
        }
    }
    error "no menubutton \"$label\""
}

# palette LAYER: screen centre of a layer's button in the toolbar (layer palette),
# scrolling the palette first if the button is out of sight. Returns {} if the layer is
# not in the palette.
proc ::rigprobe::palette {layer} {
    set fr [::rigprobe::frame]
    set b ${fr}.toolbar.canvas.frame.f${layer}.b
    if {![winfo exists $b]} { set b ${fr}.toolbar.canvas.frame.f${layer}.p }
    if {![winfo exists $b]} { return {} }
    set c ${fr}.toolbar.canvas
    update idletasks
    set top [winfo rooty $c]
    set bot [expr {$top + [winfo height $c]}]
    set y [lindex [::rigprobe::center $b] 1]
    if {$y < $top + 10 || $y > $bot - 10} {
        # Scroll so the button is near the top of the visible part of the palette.
        set fy [winfo y ${fr}.toolbar.canvas.frame.f${layer}]
        set h [winfo height ${fr}.toolbar.canvas.frame]
        if {$h > 0} { $c yview moveto [expr {double($fy) / $h}] }
        update idletasks
    }
    return [::rigprobe::center $b]
}

# um2px X Y: screen pixel for layout position (X, Y) in microns, in the first layout
# window. Uses the window's own view bounds (`view get`, internal units), so it holds at
# any zoom. Magic snaps the box to its snap grid (lambda, 0.01 um, by default) when you
# click, so a pixel within half a grid step of the target lands on it.
proc ::rigprobe::um2px {x y {win {}}} {
    if {$win eq {}} { set win [lindex [magic::windownames layout] 0] }
    update idletasks
    # `view get` answers in the units chosen with `units` (Window > Report ... units), so
    # ask for internal units and put the setting back afterwards.
    set cu [units list]
    units internal noprint
    set v [$win view get]
    units {*}$cu
    lassign $v llx lly urx ury
    set ipu [expr {1.0 / [magic::i2u 1]}]
    set ix [expr {$x * $ipu}]
    set iy [expr {$y * $ipu}]
    set px [expr {[winfo rootx $win] + ($ix - $llx) * [winfo width $win] / double($urx - $llx)}]
    set py [expr {[winfo rooty $win] + ($ury - $iy) * [winfo height $win] / double($ury - $lly)}]
    list [expr {int(round($px))}] [expr {int(round($py))}]
}

# rect WIDGET: "X Y W H" of a Tk window on the screen.
proc ::rigprobe::rect {w} {
    update idletasks
    list [winfo rootx $w] [winfo rooty $w] [winfo width $w] [winfo height $w]
}

# menurect MENU: rect of an open (posted) title-bar menu.
proc ::rigprobe::menurect {label} {
    set fr [::rigprobe::frame]
    foreach mb [winfo children ${fr}.titlebar.mbuttons] {
        if {[winfo class $mb] eq "Menubutton" && [$mb cget -text] eq $label} {
            return [::rigprobe::rect [$mb cget -menu]]
        }
    }
    error "no menubutton \"$label\""
}

# readout: the title bar as text.
proc ::rigprobe::readout {} {
    set fr [::rigprobe::frame]
    set out {}
    lappend out "caption: [${fr}.titlebar.caption cget -text]"
    lappend out "drc button: [${fr}.titlebar.drcbutton cget -text]"
    lappend out "readout: [${fr}.titlebar.pos cget -text]"
    lappend out "message: [${fr}.titlebar.message cget -text]"
    set cu [units list]
    units microns noprint
    lappend out "box (um): [box values]"
    units {*}$cu
    lappend out "snap: [snap] grid: [grid what]"
    join $out \n
}

# console_input: what is typed on the console's command line but not yet run.
proc ::rigprobe::console_input {} {
    if {[catch {tkcon console get limit "end - 1 chars"} t]} { return "" }
    string trim $t
}

# console_tail N: the last N lines of Magic's tkcon console.
proc ::rigprobe::console_tail {n} {
    if {[catch {tkcon console get "end - [expr {$n + 1}] lines" end} t]} {
        return "(no console: $t)"
    }
    string trimright $t
}


# treeitem TREE TEXT: screen centre of the first visible row of a ttk::treeview (the Cell,
# Library and DRC managers use them) whose text starts with TEXT. Opens parents and scrolls
# the row into view first. Errors if there is no such row.
proc ::rigprobe::treeitem {tree text} {
    set todo [$tree children {}]
    while {[llength $todo]} {
        set item [lindex $todo 0]
        set todo [lrange $todo 1 end]
        if {[string match "${text}*" [$tree item $item -text]]} {
            $tree see $item
            update idletasks
            lassign [$tree bbox $item] x y w h
            if {$w eq ""} { error "row \"$text\" is not visible" }
            return [list [expr {[winfo rootx $tree] + $x + 40}] \
                         [expr {[winfo rooty $tree] + $y + $h / 2}]]
        }
        set todo [concat $todo [$tree children $item]]
    }
    error "no row \"$text\" in $tree"
}

# treerows TREE: the text of every row, indented by depth (to see what a manager lists).
proc ::rigprobe::treerows {tree {parent {}} {depth 0}} {
    set out {}
    foreach item [$tree children $parent] {
        lappend out "[string repeat {  } $depth][$tree item $item -text] [$tree item $item -values]"
        set out [concat $out [::rigprobe::treerows $tree $item [expr {$depth + 1}]]]
    }
    if {$depth == 0} { return [join $out \n] }
    return $out
}

# button TEXT ?TOPLEVEL?: screen centre of the first button (or checkbutton, menubutton)
# whose -text is TEXT, searching TOPLEVEL (default: every toplevel).
proc ::rigprobe::button {text {top {}}} {
    if {$top eq {}} { set todo [winfo children .] } else { set todo [list $top] }
    while {[llength $todo]} {
        set w [lindex $todo 0]
        set todo [lrange $todo 1 end]
        if {[winfo class $w] in {Button Checkbutton Menubutton Radiobutton TButton}
                && ![catch {$w cget -text} t] && $t eq $text && [winfo ismapped $w]} {
            return [::rigprobe::center $w]
        }
        set todo [concat $todo [winfo children $w]]
    }
    error "no button \"$text\""
}

# entry LABELTEXT ?TOPLEVEL?: screen centre of the entry next to the label LABELTEXT (the
# label and entry share a parent frame, as in the gencell and text dialogs).
proc ::rigprobe::entry {text {top .}} {
    set todo [list $top]
    while {[llength $todo]} {
        set w [lindex $todo 0]
        set todo [lrange $todo 1 end]
        if {[winfo class $w] eq "Label" && ![catch {$w cget -text} t]
                && [string trim $t] eq [string trim $text]} {
            # The device dialog grids every label and entry into one frame, so take the
            # entry on the label's grid row; the text dialog packs each pair in its own
            # frame, so there the first entry beside the label is the one.
            set row {}
            if {![catch {grid info $w} gi] && [dict exists $gi -row]} { set row [dict get $gi -row] }
            foreach sib [winfo children [winfo parent $w]] {
                if {[winfo class $sib] ni {Entry TEntry} || ![winfo ismapped $sib]} continue
                if {$row ne {}} {
                    if {[catch {grid info $sib} si] || ![dict exists $si -row]} continue
                    if {[dict get $si -row] != $row} continue
                }
                return [::rigprobe::center $sib]
            }
        }
        set todo [concat $todo [winfo children $w]]
    }
    error "no entry labelled \"$text\""
}

after 200 ::rigprobe::poll
