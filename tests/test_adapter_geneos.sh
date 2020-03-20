#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2016-06-22 09:51:51 +0100 (Wed, 22 Jun 2016)
#
#  https://github.com/harisekhon/nagios-plugins
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help improve or steer this or other code I publish
#
#  https://www.linkedin.com/in/harisekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$srcdir/..";

. ./tests/utils.sh

section "G e n e o s   A d a p t e r"

# Try to make these local tests with no dependencies for simplicity

run_grep '^echo,OK,test message,10,5,1001$' ./adapter_geneos.py echo 'test message | perf1=10s;1;2 perf2=5%;80;90;0;100 perf3=1001'

run_grep '^test,OK,test message,10,5,1002$' ./adapter_geneos.py --shell --result 0 test 'message | perf1=10s;1;2 perf2=5%;80;90;0;100' perf3=1002

run_grep '^test,OK,test message,10,5,1003$' ./adapter_geneos.py --result 0 test 'message | perf1=10s;1;2 perf2=5%;80;90;0;100' perf3=1003 --shell

run_grep '^test,WARNING,test 1 message,10,5,1004$' ./adapter_geneos.py --result 1 'test 1 message | perf1=10s;1;2 perf2=5%;80;90;0;100 perf3=1004'

run_grep '^test,CRITICAL,test 2 message,10,5,1005$' ./adapter_geneos.py --result 2 'test 2 message | perf1=10s;1;2 perf2=5%;80;90;0;100 perf3=1005'

run_grep '^test,UNKNOWN,test 3 message,10,5,1006$' ./adapter_geneos.py --result 3 'test 3 message | perf1=10s;1;2 perf2=5%;80;90;0;100 perf3=1006'

run_grep '^test,DEPENDENT,test 4 message,10,5,1007$' ./adapter_geneos.py --result 4 'test 4 message | perf1=10s;1;2 perf2=5%;80;90;0;100 perf3=1007'

run_grep '^echo,OK,test message,10,5,1008$' ./adapter_geneos.py --shell "echo 'test message | perf1=10s;1;2 perf2=5%;80;90;0;100 perf3=1008'"

run ./adapter_geneos.py $perl -T ./check_disk_write.pl -d .

if is_CI; then
    echo '> git branch'
    git branch
    echo
fi
current_branch="$(git branch | grep '^\*' | sed 's/^*[[:space:]]*//;s/[()]//g')"

run ./adapter_geneos.py $perl -T ./check_git_checkout_branch.pl -d . -b "$current_branch"

echo "Testing failure detection of wrong git branch (perl):"
run_grep '^perl,CRITICAL,' ./adapter_geneos.py $perl -T ./check_git_checkout_branch.pl -d . -b nonexistentbranch

echo "Testing failure detection of wrong git branch (python):"
run_grep '^check_git_checkout_branch.py,CRITICAL,' ./adapter_geneos.py ./check_git_checkout_branch.py -d . -b nonexistentbranch

tmpfile="$(mktemp /tmp/adapter_geneos.txt.XXXXXX)"
echo test > "$tmpfile"

run ./adapter_geneos.py $perl -T ./check_file_md5.pl -f "$tmpfile" -v -c 'd8e8fca2dc0f896fd7cb4cb0031ba249'

rm -vf "$tmpfile"
hr

run ./adapter_geneos.py $perl -T ./check_timezone.pl -T "$(readlink /etc/localtime | sed 's/.*zoneinfo\///')" -A "$(date +%Z)" -T "$(readlink /etc/localtime)"

echo "Testing induced failures:"
echo
# should return zero exit code regardless but raise non-OK statuses in STATUS field
run_grep '^exit,OK,<no output>$' ./adapter_geneos.py --shell exit 0

run_grep '^exit,WARNING,<no output>$' ./adapter_geneos.py --shell exit 1

run_grep '^exit,CRITICAL,<no output>$' ./adapter_geneos.py --shell exit 2

run_grep '^exit,UNKNOWN,<no output>$' ./adapter_geneos.py --shell exit 3

run_grep '^exit,UNKNOWN,<no output>$' ./adapter_geneos.py --shell exit 5

run_grep '^nonexistentcommand,UNKNOWN,' ./adapter_geneos.py nonexistentcommand arg1 arg2

run_grep '^nonexistentcommand,UNKNOWN,' ./adapter_geneos.py --shell nonexistentcommand arg1 arg2

run_grep '^perl,UNKNOWN,usage: check_disk_write.pl ' ./adapter_geneos.py $perl -T check_disk_write.pl --help

echo "Completed $run_count Geneos adapter tests"
echo
echo "All Geneos adapter tests completed successfully"
echo
echo
