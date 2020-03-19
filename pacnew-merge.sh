#!/bin/sh
# Script to aid merging of .pacnew files on Arch Linux
#
# Copyright (c) 2020 Andrew Sveikauskas
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

set -e -o pipefail

find_pacnews() {
   for dir in /etc /usr /var; do
      find "$dir" -name '*.pacnew'
   done | grep '.pacnew$' | sed -e 's/\.pacnew$//' || true
}

prompt() {
   echo Options: 1>&2

   for i in "$@"; do echo $i 1>&2; done
   while true; do
      echo -n '> ' 1>&2
      read response
      case "$response" in
      '?'|help|h|H)
         for i in "$@"; do echo $i 1>&2; done
         continue
         ;;
      *) ;;
      esac
      for i in "$@"; do
         i="`echo "$i" | cut -d : -f 1`"
         if [ "$i" == "$response" ]; then
            echo $i
            return
         fi
      done
      echo 'Invalid option.  Type '\'?\'' for details' 1>&2
   done
}

merge_file() {
   old="$1"
   new="$2"

   merged=""

   while true; do
      x="`prompt 's: Skip this file' \
                 'D: Delete the new file' \
                 'N: Take the new file' \
                 'd: Diff between old and new' \
                 'm: Use sdiff(1) to merge old and new' \
                 'e: Edit merged file' \
                 'dm: Diff between old and merged' \
                 'am: Accept merged file' \
                 'q: quit' < /dev/tty 2>/dev/tty`"
      case "$x" in
      s)
         break
         ;;
      D)
         rm "$new"
         break
         ;;
      N)
         mv "$new" "$old"
         break
         ;;
      d)
         diff -u "$old" "$new" | less || true
         ;;
      m)
         if [ ! -f "$merged" ]; then
            merged=`mktemp`
         fi
         sdiff -o "$merged" -sd "$old" "$new" </dev/tty>/dev/tty || true
         ;;
      e)
         if [ ! -f "$merged" ]; then
            echo Merged file does not exist.  Try \'m\'.
            continue
         fi
         ${EDITOR-vi} "$merged" </dev/tty>/dev/tty || true
         ;;
      dm)
         if [ ! -f "$merged" ]; then
            echo Merged file does not exist.  Try \'m\'.
            continue
         fi
         diff -u "$old" "$merged" | less || true
         ;;
      am)
         if [ ! -f "$merged" ]; then
            echo Merged file does not exist.  Try \'m\'.
            continue
         fi
         chmod `stat -c '%a' "$old"` "$merged"
         chown `stat -c '%U:%G' "$old"` "$merged"
         mv "$merged" "$old"
         merged=""
         rm "$new"
         break;
         ;;
      q)
         if [ -f "$merged" ]; then rm "$merged"; fi
         exit 0
         ;;
      *) ;;
      esac
   done
   if [ -f "$merged" ]; then rm "$merged"; fi
}

require() {
   for i in "$@"; do
      which "$i" >/dev/null 2>&1 || \
         (echo Could not find required dependency \""$i"\" on PATH 1>&2; false)
   done
}

require id find grep sed cut rm mv chown chmod stat diff sdiff ${EDITOR-vi}

[ -t 0 ] && [ -t 1 ] || (echo 'Needs to run interactively.' 1>&2; false)

if [ "`id -u`" -ne 0 ]; then
   echo -n 'You do not appear to be root.  Continue?  [y] '
   while true; do
      read response
      case "$response" in
      ''|y|Y)
         break
         ;;
      n|N)
         exit
         ;;
      *)
         echo -n 'Please enter 'y' or 'n'.  [y] '
         ;;
      esac
   done
fi

find_pacnews | while read file; do
   echo Found pacnew for: $file
   merge_file "$file" "$file.pacnew"
done
