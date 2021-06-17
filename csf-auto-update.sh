#/usr/bin/env bash
ips_link='https://www.quic.cloud/ips?ln'
csf_allow_file='/etc/csf/csf.allow'
csf_allow_bak_file='/etc/csf/csf.allow.bak'
csf_ignore_file='/etc/csf/csf.ignore'
csf_ignore_bak_file='/etc/csf/csf.ignore.bak'
exit_flag=0
EPACE='        '

check_input(){
    if [ -z "${1}" ]; then
        help_message
        exit 1
    fi
}

check_environment(){
    if [ ! -f "$csf_allow_file" ]; then
        echo "$csf_allow_file does not exists"
        exit_flag=1;
    fi
    if [ ! -f "$csf_ignore_file" ]; then
        echo "$csf_ignore_file does not exists"
        exit_flag=1;
    fi
    if [ ${1} = "-r" ] && [ ! -f "$csf_ignore_bak_file" ] ; then
        echo "$csf_ignore_bak_file does not exists"
        exit_flag=1;
    fi

    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root user!"
        exit_flag=1;
    fi

    curl -m 5 -s https://www.quic.cloud/ips?ln >/dev/null 2>&1
    if [ ${?} != 0 ]; then 
        echo "${ips_link} not working, please check!"
        exit_flag=1;
    fi
    if [ $exit_flag = "0" ]; then
        echo "[Success] Environment checked!!"
    else
        echo "[ERROR] Failed Verificaion!!"
        exit 1;
    fi
}

echow(){
    FLAG=${1}
    shift
    echo -e "\033[1m${EPACE}${FLAG}\033[0m${@}"
}


help_message(){
    echo -e "\033[1mOPTIONS\033[0m"
    echow '-u, --update'
    echo "${EPACE}${EPACE}Backup csf.allow and csf.ignore to csf.allow.bak and csf.ignore.bak"
    echo "${EPACE}${EPACE}Update quic.cloud/ips whitelist to csf.allow and csf.ignore list"
    echow '-r, --restore'
    echo "${EPACE}${EPACE}Restore csf.allow and csf.ignore from csf.allow.bak and csf.ignore.bak"
    echow '-h, --help'
    echo "${EPACE}${EPACE}Display help."
}

resotre_csf_setting(){
    echo 'Restore csf'
    while read line;
    do
        csf -ar $line
    done < <(curl -ks $ips_link)
    cp $csf_ignore_bak_file $csf_ignore_file
    csf -ra
}

update_csf_setting(){
    echo 'Update CSF csf.allow'
    while read line;
    do
        csf -a $line \# quic.cloud whitelist;
    done < <(curl -ks $ips_link)
    echo 'Update CSF csf.ignore'
    cp $csf_ignore_file $csf_ignore_bak_file
    curl -ks $ips_link >> $csf_ignore_file
    echo 'Restart csf'
    csf -ra
}

check_input ${1}
if [ ! -z "${1}" ]; then
    case ${1} in
        -[hH] | -help | --help)
            help_message
            ;;
        -[uU] | -update | --update)
            check_environment "-u"
            update_csf_setting
            ;;
        -[rR] | -restore | --restor)
            check_environment "-r"
            resotre_csf_setting
            ;;
        *)
            help_message
           ;;
    esac
fi
