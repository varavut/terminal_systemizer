#!/system/bin/sh
# Workaround for Android 14+: PMS no longer retroactively grants priv-app
# permissions to user-installed apps via a Magisk overlay alone. We parse
# each systemized app's privapp-permissions XML (already written by systemize)
# and grant the listed permissions via pm grant. This works because privileged
# permissions with protectionLevel=development (e.g. CAPTURE_AUDIO_OUTPUT,
# READ_PRIVILEGED_PHONE_STATE) can be granted at runtime by root.
# On older Android where the overlay approach already works, pm grant is a no-op.

MODDIR="/data/adb/modules/terminal_systemizer"
PERM_DIR="$MODDIR/system/etc/permissions"
LIST="$MODDIR/systemize.list"

[ -f "$LIST" ] || exit 0

# Wait for PackageManager to be fully ready
until pm list packages > /dev/null 2>&1; do sleep 2; done
sleep 5

while IFS= read -r line; do
    pkg=$(echo "$line" | cut -d'^' -f4)
    [ -z "$pkg" ] && continue
    xml="$PERM_DIR/privapp-permissions-${pkg}.xml"
    [ -f "$xml" ] || continue
    grep -o 'name="[^"]*"' "$xml" | sed 's/name="//;s/"//' | while read -r perm; do
        pm grant "$pkg" "$perm" 2>/dev/null
    done
done < "$LIST"
