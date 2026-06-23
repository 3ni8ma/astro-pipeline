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

mkdir -p src/__tests__

cat > src/__tests__/setup.ts << 'EOF'
import '@testing-library/jest-dom';
EOF

cat > src/__tests__/useToggle.test.tsx << 'EOF'
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useToggle } from '../useToggle';

describe('useToggle', () => {
  it('starts with default value (false)', () => {
    const { result } = renderHook(() => useToggle());
    expect(result.current.value).toBe(false);
  });

  it('starts with provided initial value', () => {
    const { result } = renderHook(() => useToggle(true));
    expect(result.current.value).toBe(true);
  });

  it('toggles the value', () => {
    const { result } = renderHook(() => useToggle());
    act(() => result.current.toggle());
    expect(result.current.value).toBe(true);
    act(() => result.current.toggle());
    expect(result.current.value).toBe(false);
  });

  it('sets value to true', () => {
    const { result } = renderHook(() => useToggle());
    act(() => result.current.setTrue());
    expect(result.current.value).toBe(true);
  });

  it('sets value to false', () => {
    const { result } = renderHook(() => useToggle(true));
    act(() => result.current.setFalse());
    expect(result.current.value).toBe(false);
  });

  it('sets a specific value', () => {
    const { result } = renderHook(() => useToggle());
    act(() => result.current.set(true));
    expect(result.current.value).toBe(true);
    act(() => result.current.set(false));
    expect(result.current.value).toBe(false);
  });
});
EOF

sed -i "1s/^/\/\/ Updated: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/__tests__/useToggle.test.tsx

cat > src/__tests__/useDocumentTitle.test.tsx << 'EOF'
import { renderHook } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useDocumentTitle } from '../useDocumentTitle';

describe('useDocumentTitle', () => {
  it('sets the document title', () => {
    renderHook(() => useDocumentTitle('Test Title'));
    expect(document.title).toBe('Test Title');
  });

  it('restores previous title on unmount', () => {
    document.title = 'Original';
    const { unmount } = renderHook(() => useDocumentTitle('Temporary'));
    expect(document.title).toBe('Temporary');
    unmount();
    expect(document.title).toBe('Original');
  });

  it('does not restore when preserveOnUnmount is true', () => {
    document.title = 'Original';
    const { unmount } = renderHook(() => useDocumentTitle('Temporary', true));
    expect(document.title).toBe('Temporary');
    unmount();
    expect(document.title).toBe('Temporary');
  });
});
EOF

sed -i "1s/^/\/\/ Updated: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/__tests__/useDocumentTitle.test.tsx

cat > src/__tests__/useOnlineStatus.test.tsx << 'EOF'
import { renderHook, act } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { useOnlineStatus } from '../useOnlineStatus';

describe('useOnlineStatus', () => {
  it('returns a boolean', () => {
    const { result } = renderHook(() => useOnlineStatus());
    expect(typeof result.current).toBe('boolean');
  });

  it('responds to online events', () => {
    const { result } = renderHook(() => useOnlineStatus());
    act(() => { window.dispatchEvent(new Event('online')); });
    expect(result.current).toBe(true);
  });

  it('responds to offline events', () => {
    const { result } = renderHook(() => useOnlineStatus());
    act(() => { window.dispatchEvent(new Event('offline')); });
    expect(result.current).toBe(false);
  });
});
EOF

sed -i "1s/^/\/\/ Updated: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/__tests__/useOnlineStatus.test.tsx

cat > vitest.config.ts << 'EOF'
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/__tests__/setup.ts'],
    globals: true,
  },
});
EOF

npm pkg set scripts.test="vitest run" 2>/dev/null || true
npm pkg set scripts["test:watch"]="vitest" 2>/dev/null || true

npm install --save-dev @testing-library/jest-dom 2>&1 | tail -1

git add -A
git diff --staged --quiet || (git commit -m "Update react-hooks tests: $(date '+%Y-%m-%d %H:%M') [skip ci]" && git push origin HEAD 2>&1 | tee -a "$LOG_FILE" && log "react-hooks: Tests updated.") || log "react-hooks: No changes."

cd "$PIPELINE_DIR"
