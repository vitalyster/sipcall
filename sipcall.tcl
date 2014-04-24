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
	hook::add connected_hook [namespace current]::register_sip 50
    }

    proc unload {} {
	puts "SIP plugin unloaded"
	hook::remove open_chat_post_hook [namespace current]::call_button 50
	hook::add disconnected_hook [namespace current]::unregister_sip 50
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

namespace eval ::xmpp::dns {
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
	-command [namespace code [list call_user $chatid]]
    pack $cw.status.callbutton -side right -after $cw.status.mb
}

proc sipcall::call_user {chatid} {
    variable sipctx
    set jid [::xmpp::jid::removeResource [chat::get_jid $chatid]]
    if {[info exists sipctx($jid)]} {
	switch -- $sipctx($jid) {
	    error {
		return
	    }
	    progress {
		[namespace current]::status $jid "Wait..."
		return
	    }
	    call {
		[namespace current]::status $jid "SIP call hangup"		
		pjsip::hangup
		set sipctx($jid) ok
		return
	    }
	}
    }
    set sipctx($jid) progress
    
    if {[catch { ::xmpp::dns::resolveSIPU [::xmpp::jid::server $jid] }]} {
	[namespace current]::status $jid "$jid does not support SIP calls"
	set sipctx($jid) error
    } else {
	[namespace current]::status $jid "Dialing..."
	set sipctx($jid) call
	pjsip::dial sip:$jid		    
    }
}

proc sipcall::onregistered {id} {
    puts "$id registered"
}

proc sipcall::onstatechanged {callno callid state args} {
    puts $callno$callid$state$args
}

proc sipcall::status {jid text} {
    set xlib [lindex [lindex $::connections 0] 0]
    set chatid [::chat::chatid $xlib $jid]
    ::chat::add_message $chatid $jid {info} $text {}
}

proc sipcall::onmedia {callNo accountID mediaState durationSec remoteInfo} {
    tk_messageBox -message $mediaState$durationSec$remoteInfo -type ok
}

proc sipcall::onincoming {callNo accountID remoteInfo localInfo} {
    variable sipctx
    set remote [lindex [split $remoteInfo {:>}] 1]
    set answer [tk_messageBox -message "Incoming call $remote, answer?" -type yesno]
    switch -- $answer {
	yes {
	    [namespace current]::status $remote "SIP call started"	    
	    pjsip::answer
	    set sipctx($remote) call
	}
	no {
	    [namespace current]::status $remote "SIP call rejected"
	    pjsip::reject
	    set sipctx($remote) ok
	}
    }
}

proc sipcall::register_sip {xlib} {
    set jid [connection_jid $xlib]
    set user [::xmpp::jid::node $jid]
    set server [::xmpp::jid::server $jid]
    set sipuri sip:[::xmpp::jid::removeResource $jid]
    pjsip::notify <Registration> [namespace current]::onregistered
    pjsip::notify <State> [namespace current]::onstatechanged
    pjsip::notify <Incoming> [namespace current]::onincoming
    pjsip::notify <Media> [namespace current]::onmedia
    pjsip::register sip:$server $sipuri $server $user $::loginconf(password) stun.jabber.ru
}
