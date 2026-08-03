#!/bin/zsh
set -u

print "JD Desk Hub read-only macOS smart-card diagnostic"
print "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
print "macOS: $(sw_vers -productVersion 2>/dev/null || print unknown)"

print "\nUSB modem ports:"
for port in /dev/cu.usbmodem*(N); do print "$port"; done

print "\nSmart-card inventory:"
system_profiler SPSmartCardsDataType 2>&1

print "\nPIV identities:"
sc_auth identities 2>&1

print "\nPairings for current user:"
sc_auth list -u "$USER" -v 2>&1

print "\nThis script does not pair, unpair, edit PAM, or change system state."
