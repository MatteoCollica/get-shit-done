# workmode

An easy to use bash script that blocks websites known to distract us from our work.

After cloning this repository, put it in your $PATH and ensure it is executable.

Executing as root is needed because it modifies your hosts file and restarts your network daemon.

## To enable workmode

    $ sudo workmode work

## To disable workmode

    $ sudo workmode play
    
## To check if workmode is enabled

    $ workmode check

### $site_list

Add or remove elements of this array for sites to block or unblock.

### ~/.config/workmode.ini

Appends additional sites to block.  Duplicates will be removed, and www is prepended.

    sites = foo.com, bar.com, baz.com

### $hosts_file

Update this variable to point to the location of your hosts file. Make sure it is an absolute path.
