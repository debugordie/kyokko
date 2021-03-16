set TOP [ file dirname [ file dirname [ file normalize [ info script ] ] ] ]
puts "Project root: ${TOP}"

proc fileext { str } {
    set sp [split $str "."]
    return [lindex $sp [llength $sp]-1]
}

