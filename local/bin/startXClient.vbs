' This script can be used to start any X-windows client app running in WSL2.
' h/t: https://medium.com/@bhupathy/install-terminator-on-windows-with-wsl-2826591d2156
'
' How to use this script.
' 1. First time setup:
'    * Check this file out from git and install it in %USERPROFILE%\local\bin.
' 2. For each X-client app (in this example, the 'terminator' linux console app):
'    * Create a shortcut on the desktop. Edit it's properties as follows:
'      Target   = "C:\Windows\System32\wscript.exe C:\Users\lb999\local\bin\startXClient.vbs terminator"
'      Start in = "\\wsl$\Ubuntu-20.04\home\larry"
'    * Rename the shortcut to 'Terminator'.
'    * Copy/Move the shortcut to %USERPROFILE%\AppData\Roaming\Microsoft\Windows\"Start Menu"
'
set objArgs = Wscript.Arguments

xclient = objArgs(0)
xargs = objArgs(1)

set shell = CreateObject("Wscript.Shell")

xServerProcessName = "vcxsrv.exe"

RunXserverProcess( xServerProcessName )

RunXClient(xclient, xargs)

'KillXserverProcess( xServerProcessName )

function RunXserverProcess( strProcess )
    'https://gist.github.com/avinoamsn/495db3729d6b24ec065a710250657c16
    if getProcessObject(strProcess) is Nothing Then
        shell.exec "C:\Program Files\VcXsrv\" & strProcess & " :0 -ac -terminate -lesspointer -multiwindow -clipboard -wgl -dpi auto"
    end if
end function

function RunXClient(ByVal client, ByVal args)
    'https://stackoverflow.com/questions/38969503/shellexecute-and-wait
    'Wscript.Shell.Run instead of Wscript.Shell.Application.ShellExecute - avoid async shell run and allow execution of code bellow
    'Larry's addition
    acmd = "C:\Windows\System32\wsl.exe -d Ubuntu-20.04 -u larry " &_
        "bash -l -c ""cd ~/; . ~/.profile; DISPLAY=$(cat /etc/resolv.conf | grep nameserver | " &_
        "awk '{print $2}'):0 " & client & " --geometry=1260x450"""
    shell.run acmd, 0, true
end function

function KillXserverProcess ( strProcess )
    'Check if another bash process is running to avoid closing xServer
    if Not getProcessObject("bash") is Nothing Then
        exit function
    end if

    set Process = getProcessObject(strProcess)
    if Not Process is Nothing Then
        Process.terminate
    end if
end function

function getProcessObject ( strProcess )
    ' https://stackoverflow.com/questions/19794726/vb-script-how-to-tell-if-a-program-is-already-running
    Dim Process, strObject : strObject = "winmgmts://."
    For Each Process in GetObject( strObject ).InstancesOf( "win32_process" )
    if UCase( Process.name ) = UCase( strProcess ) Then
        set getProcessObject = Process
        exit Function
    end if
    Next
    set getProcessObject = Nothing
end function
