#==========================================================================
#  GENXML.TCL -
#            part of the GNED, the Tcl/Tk graphical topology editor of
#                            OMNeT++
#
#   By Andras Varga
#
#==========================================================================

#----------------------------------------------------------------#
#  Copyright (C) 1992,99 Andras Varga
#  Technical University of Budapest, Dept. of Telecommunications,
#  Stoczek u.2, H-1111 Budapest, Hungary.
#
#  This file is distributed WITHOUT ANY WARRANTY. See the file
#  `license' for details on this and other legal matters.
#----------------------------------------------------------------#


foreach i {label-cid icon-cid rect-cid rect2-cid arrow-cid background-cid
           dirty unnamed selected
           disp-icon
           disp-fillcolor disp-outlinecolor disp-linethickness
           disp-drawmode disp-src-anchor-x disp-src-anchor-y
           disp-dest-anchor-x disp-dest-anchor-y
           disp-xpos disp-ypos disp-xsize disp-ysize} {
   set ned_internal($i) 1
}

proc saveXML {nedfilekey fname} {
   global ned

   if [catch {
       busy "Saving $fname..."
       set fout [open $fname w]
       puts $fout [generateXML $nedfilekey]
       close $fout
       busy
   } errmsg] {
       tk_messageBox -icon warning -type ok -message "Error: $errmsg"
       busy
       return
   }
}


proc generateXML {key} {
    update_displaystrings $key

    set xml ""
    append xml "<!-- XML file format for NED is currently ***EXPERIMENTAL*** -->\n"
    append xml "<?xml version=\"1.0\" ?>\n"
    append xml "<!doctype system=\"ned1.dtd\">\n\n"

    append xml [generateXMLElement $key ""]
    return $xml
}


proc generateXMLElement {key indent} {
    global ned ned_attlist ned_internal

    # TclXML parser doesn't understand <tag .. /> syntax
    set needs_separate_endtag 1

    # generate attributes
    set type $ned($key,type)
    set out ""
    append out "$indent<$type id=\"$key\"\n"
    foreach field [lsort $ned_attlist($type)] {
        if {![info exist ned_internal($field)]} {
            set val $ned($key,$field)
            regsub -all "\n" $val "%0d%0a" val
            regsub -all "\"" $val "%22" val
            append out "$indent  $field=\"$val\"\n"
        }
    }

    # generate children if there are any
    set childkeys $ned($key,childrenkeys)
    if {!$needs_separate_endtag && [llength $childkeys]==0} {
        append out "$indent  />\n"
    } else {
        append out "$indent  >\n"

        set indent2 "$indent    "
        foreach i $childkeys {
            append out [generateXMLElement $i $indent2]
        }
        append out "$indent</$type>\n"
    }
    return $out
}



