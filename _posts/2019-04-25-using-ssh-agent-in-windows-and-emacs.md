---
layout: post
title:  Using Ssh Agent in Windows and Emacs
date:   2019-04-25 09:19:12 +0300
tags: [ssh, powershell, emacs, git]
---

The SSH Agent allows you to remember the password for a password protected SSH private key during your session. While Linux usually is able to handle this rather elegantly using it's key stores like the gnome-keyring (for KDE I think it's still disappointingly [complicated](https://milosophical.me/blog/2015/loading-ssh-keys-at-kde-startup.html)), in Windows it's still a bit of a second class citizen.

My Windows workflow usually involves some Git in Emacs (magit) and Powershell usage, so here's a configuration that initializes the SSH Agent when you start a Powershell session. 

In %HOMEPATH%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1 is have:

{% highlight powershell %}
Import-Module 'C:\tatu\Apps\posh-git\src\posh-git.psd1'

& {
    function Load-Agent-Variables() {
        param($connection)
        $agent = $connection | Select-String -Pattern "SSH_AGENT_PID=(\d+);"
        if ($agent) {
            Write-Host "Loading ssh agent"
            $socket = $connection | Select-String -Pattern "SSH_AUTH_SOCK=(.*?);" 
            $SSH_AGENT_PID = $agent.Matches.Groups[1].Value
            $SSH_AGENT_SOCKET = $socket.Matches.Groups[1].Value
            
            $env:SSH_AUTH_SOCK=$SSH_AGENT_SOCKET
            $env:SSH_AGENT_PID=$SSH_AGENT_PID
        }
    }

    
    $running = ps ssh-agent -ErrorAction SilentlyContinue
    if ($running -and (Test-Path $env:TEMP\ssh_agent.pid)) {
        $connection = Get-Content $env:TEMP\ssh_agent.pid
        Load-Agent-Variables $connection
    } else {
        $connection = . ssh-agent | Out-String
        $connection | Out-File $env:TEMP\ssh_agent.pid
        Load-Agent-Variables $connection
        Write-Host "Adding Private Key"
        ssh-add 
    }
}
{% endhighlight %}


It loads [posh-git](https://github.com/dahlbyk/posh-git) and then loads the SSH Agent and stores the output into a file. Then we use this file to load the running SSH Agent in subsequent Powershell sessions.

## Emacs 

Then in emacs I can read this file and set the environment variables in place in my .emacs:

{% highlight emacs-lisp %}
(defun load-agent-socket-env()
  (interactive)
  (defvar pid_file (concat (getenv "TEMP") "\\" "ssh_agent.pid"))
  (if (file-exists-p pid_file)
      (setenv "SSH_AUTH_SOCK" (save-excursion
                                (with-temp-buffer
                                  (insert-file-contents pid_file)
                                  (goto-char 1)
                                  (re-search-forward "SSH_AUTH_SOCK=\\(.*?\\);")
                                  (match-string 1)
                                  ))
              )
    
    
    (setenv "SSH_AGENT_PID" (save-excursion
                              (with-temp-buffer
                                (insert-file-contents pid_file)
                                (goto-char 1)
                                (re-search-forward "SSH_AGENT_PID=\\(.*?\\);")
                                (match-string 1)
                                ))
            )
    
    )
  )

(load-agent-socket-env)
{% endhighlight %}

That's it! Now Emacs is able to use the SSH Agent to use SSH keys.
