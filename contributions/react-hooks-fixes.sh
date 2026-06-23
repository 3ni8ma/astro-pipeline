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

cat > src/useDebounce.ts << 'EOF'
import { useState, useEffect, useRef, useCallback } from 'react';

export function useDebounce<T>(value: T, delay: number = 500): [T, () => void] {
  const [debouncedValue, setDebouncedValue] = useState<T>(value);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    timerRef.current = setTimeout(() => setDebouncedValue(value), delay);
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
    };
  }, [value, delay]);

  const cancel = useCallback(() => {
    if (timerRef.current) {
      clearTimeout(timerRef.current);
      timerRef.current = null;
    }
  }, []);

  return [debouncedValue, cancel];
}
EOF

sed -i "1s/^/\/\/ Update: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/useDebounce.ts

cat > src/useLocalStorage.ts << 'EOF'
import { useState, useCallback, useEffect } from 'react';

export function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T | ((prev: T) => T)) => void] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      const item = localStorage.getItem(key);
      return item ? (JSON.parse(item) as T) : initialValue;
    } catch {
      return initialValue;
    }
  });

  const setValue = useCallback((value: T | ((prev: T) => T)) => {
    setStoredValue(prev => {
      const nextValue = value instanceof Function ? value(prev) : value;
      try {
        localStorage.setItem(key, JSON.stringify(nextValue));
      } catch {
        // Storage full or unavailable
      }
      return nextValue;
    });
  }, [key]);

  useEffect(() => {
    const handler = (event: StorageEvent) => {
      if (event.key === key && event.newValue !== null) {
        try {
          setStoredValue(JSON.parse(event.newValue) as T);
        } catch {
          // Invalid JSON in storage
        }
      }
    };
    window.addEventListener('storage', handler);
    return () => window.removeEventListener('storage', handler);
  }, [key]);

  return [storedValue, setValue];
}
EOF

sed -i "1s/^/\/\/ Update: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/useLocalStorage.ts

git add src/useDebounce.ts src/useLocalStorage.ts
git diff --staged --quiet || (git commit -m "Update react-hooks: $(date '+%Y-%m-%d %H:%M') [skip ci]" && git push origin HEAD 2>&1 | tee -a "$LOG_FILE" && log "react-hooks: Updated and pushed.") || log "react-hooks: No changes."

cd "$PIPELINE_DIR"
