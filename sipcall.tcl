namespace eval sipcall {
    package require xmpp::dns
    package require xmpp::jid
    
    if {[catch {package require pjsiptcl}] } {
	puts stderr "pjsiptcl not found"
	return
    }
    if {![::plugins::is_registered sipcall]} {
	::plugins::register sipcall \
	    -namespace [namespace current] \
	    -source [info script] \
	    -description [::msgcat::mc \
			      "Whether the SIP plugin is loaded."] \
	    -loadcommand [namespace code load] \
	    -unloadcommand [namespace code unload]
	return
    }


    proc load {} {
	puts "SIP plugin loaded"
	hook::add open_chat_post_hook [namespace current]::call_button 50
    }

    proc unload {} {
	puts "SIP plugin unloaded"
	hook::remove open_chat_post_hook [namespace current]::call_button 50
    }

    variable themes
    set dirs \
	[glob -nocomplain -directory [file join [file dirname [info script]] \
						pixmaps] *]
    foreach dir $dirs {
	pixmaps::load_theme_name [namespace current]::themes $dir
    }
    set values {}
    foreach theme [lsort [array names themes]] {
	lappend values $theme $theme
    }
    custom::defgroup Plugins [::msgcat::mc "Plugins options."] \
	-group Tkabber

    custom::defgroup SIP [::msgcat::mc "SIP plugin options."] \
	-group Plugins

    custom::defvar options(theme) fontawesome \
	[::msgcat::mc "SIP icons theme."] -group SIP \
	-type options -values $values \
	-command [namespace current]::load_stored_theme
    
}

namespace eval xmpp::dns {
    proc resolveSIPU {domain args} {
	return [eval [list resolveSRV _sip._udp $domain] $args]
    }
}

proc sipcall::load_stored_theme {args} {
    variable options
    variable themes

    pixmaps::load_dir $themes($options(theme))
}

proc sipcall::call_button {chatid type} {

    if {$type ne "chat"} {
	return
    }
    
    set cw [chat::winid $chatid]

    Button $cw.status.callbutton \
	-image sipcall/call \
	-helptype balloon \
	-height 24 \
	-width 24 \
	-relief flat \
	-state normal \
	-command [namespace code [list show_info $chatid]]
    pack $cw.status.callbutton -side right -after $cw.status.mb
}

proc sipcall::show_info {chatid} {
    set jid [chat::get_jid $chatid]
    set sipsrv [::xmpp::dns::resolveSIPU [xmpp::jid::node $jid]]
    [tk_messageBox -message $sipsrv -type ok]
}
