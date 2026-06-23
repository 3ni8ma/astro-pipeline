#!/usr/bin/env bash
set -euo pipefail

REPO="$GITHUB_USER/react-hooks"
DIR="$REPOS_DIR/react-hooks"

if [ ! -d "$DIR" ]; then
  gh repo clone "$REPO" "$DIR"
fi

cd "$DIR"
git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
git pull origin HEAD 2>&1 | tee -a "$LOG_FILE"

cat > src/usePrevious.ts << 'EOF'
import { useRef, useEffect } from 'react';

export function usePrevious<T>(value: T): T | undefined {
  const ref = useRef<T>(undefined);
  useEffect(() => {
    ref.current = value;
  });
  return ref.current;
}
EOF

sed -i "1s/^/\/\/ Update: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/usePrevious.ts

cat > src/useEventListener.ts << 'EOF'
import { useEffect, useRef } from 'react';

type EventMap = WindowEventMap & HTMLElementEventMap & DocumentEventMap;

export function useEventListener<K extends keyof EventMap>(
  eventName: K,
  handler: (event: EventMap[K]) => void,
  element?: EventTarget | null,
  options?: boolean | AddEventListenerOptions,
): void {
  const savedHandler = useRef(handler);
  savedHandler.current = handler;

  useEffect(() => {
    const target = element ?? window;
    if (!target?.addEventListener) return;
    const listener = (event: Event) => savedHandler.current(event as EventMap[K]);
    target.addEventListener(eventName as string, listener, options);
    return () => target.removeEventListener(eventName as string, listener, options);
  }, [eventName, element, options]);
}
EOF

sed -i "1s/^/\/\/ Update: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/useEventListener.ts

sed -i "s/export { useClipboard } from \".\/useClipboard\";/export { useClipboard } from \".\/useClipboard\";\nexport { usePrevious } from \".\/usePrevious\";\nexport { useEventListener } from \".\/useEventListener\";/" src/index.ts 2>/dev/null || \
sed -i "s/export { useClipboard } from \".\/useClipboard\";/export { useClipboard } from \".\/useClipboard\";\nexport { usePrevious } from \".\/usePrevious\";\nexport { useEventListener } from \".\/useEventListener\";/" src/index.ts

git add src/usePrevious.ts src/useEventListener.ts src/index.ts
git diff --staged --quiet || (git commit -m "Update react-hooks: new hooks $(date '+%Y-%m-%d %H:%M') [skip ci]" && git push origin HEAD 2>&1 | tee -a "$LOG_FILE" && log "react-hooks: New hooks updated.") || log "react-hooks: No changes."

cd "$PIPELINE_DIR"
