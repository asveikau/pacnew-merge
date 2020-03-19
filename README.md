# pacnew-merge.sh

This script came about when I had a single Arch Linux machine with a large
amount of `.pacnew` files in `/etc`, to the point where some system services
weren't starting correctly.

I am more used to package managers which try to automatically merge `/etc`,
so I wrote this script trying to match the sort of 3-way merge prompt we get
with, say, `sysmerge` on OpenBSD.  It does not rival that experience, but we can
at least invoke `sdiff(1)` to get most of the way there.  YMMV.  Provided
without warranty.
