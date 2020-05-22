#!/bin/bash

E_NO_PARAMS=1
E_USER_NOT_ROOT=2
E_NO_HOSTS_FILE=3
E_ALREADY_SET=4
E_WEIRD_PARAMS=5

exit_with_error()
{
    # output to stderr
    echo $2 >&2

    print_help

    exit $1
}

to_lower() { echo $1 | tr '[A-Z]' '[a-z]'; }

print_help()
{
    cat <<EOF
Usage: `basename $0` [work | play | check]
EOF
}

# just appends sites lines to the
# end of first param file
work()
{
    # if no hosts file found...
    [ -e "$1" ] || exit_with_error $E_NO_HOSTS_FILE "No hosts file found"

    ini_file="$HOME/.config/workmode.ini"

    site_list=( 'reddit.com' 'somethingawful.com'
        'digg.com' 'break.com' 'news.ycombinator.com'
        'infoq.com' 'twitter.com' 'netflix.com'
        'facebook.com' 'youtube.com' 'instagram.com'
        'vimeo.com' 'del.icio.us' 'flickr.com'
        'hi5.com' 'linkedin.com' 'tiktok.com'
        'livejournal.com' 'meetup.com' 'myspace.com'
        'plurk.com' 'stumbleupon.com'
        'yelp.com' 'slashdot.org' )

    # add sites from ini file
    # to site_list array
    sites_from_ini $ini_file

    file="$1"
    
    check $1 && exit_with_error $E_ALREADY_SET "Work mode already set."

    echo $start_token >> $file

    for site in "${site_list[@]}"
    do
        echo -e "127.0.0.1\t$site" >> $file
        echo -e "127.0.0.1\twww.$site" >> $file
    done

    echo $end_token >> $file

    $restart_network
}

play()
{
    # removes $start_token-$end_token section
    # in any place of hosts file (not only in the end)
    sed_script="{
s/$end_token/$end_token/
t finished_sites
s/$start_token/$start_token/
x
t started_sites
s/$start_token/$start_token/
x
t started_sites
p
b end
: started_sites
d
: finished_sites
x
d
: end
d
}"
    # if no hosts file found...
    [ -e "$1" ] || exit_with_error $E_NO_HOSTS_FILE "No hosts file found"
    check $1 || exit_with_error $E_ALREADY_SET "Work mode already unset."

    file=$1

    sed --in-place -e "$sed_script" $file

    $restart_network
}

check()
{
    # check if work mode has been set
    if grep "$start_token" $1 &> /dev/null; then
        if grep "$end_token" $1 &> /dev/null; then
            return 0
        fi
    fi
    return 1
}

sites_from_ini()
{
    [ -e "$1" ] || return 1

    # read all lines from ini file
    while read line
    do
        # split the equals sign
        arr=( ${line/=/" "} )
        key=${arr[0]}
        value=${arr[1]}

        # just save sites variable
        if [ "sites" == $key ]; then
            # remove trailing commas
            clean_arr=$(echo "$value" | sed "s/,*$//")
            # and leading
            clean_arr=$(echo "$clean_arr" | sed "s/^,*//")
            sites_arr=$(echo $clean_arr | tr ',' "\n")

            # get array size
            count=${#site_list[*]}

            # add all sites to global sites array 
            for site in $sites_arr
            do
                site_list[$count]=$site
                ((count++))
            done
        fi
        
    done < "$1"
}

# check for input parameters
[[ "$#" -eq 0 ]] && exit_with_error $E_NO_PARAMS "No parameters given"

# run from root user
# to change hosts file
[ "$(whoami)" == "root" -o "$1" == "check" ] || exit_with_error $E_USER_NOT_ROOT "Please, run from root"

if [ "$(uname -s)" == "Linux" ]; then
    restart_network="/etc/init.d/networking restart"
elif [ "$(uname -s)" == "Darwin" ]; then
    restart_network="dscacheutil -flushcache"
fi

##############################

hosts_file="/etc/hosts"
start_token="## start-wm"
end_token="## end=wm"

action=$1

case "$action" in
    "play")
        play $hosts_file ;;
    "work")
        work $hosts_file ;;
    "check")
        check $hosts_file && echo "Work mode is set." || echo "Work mode isn't set." ;;
    *) exit_with_error $E_WEIRD_PARAMS "Some weird params given" ;;
esac
