#!/usr/bin/env bash
set -euo pipefail

REPO="$GITHUB_USER/aarushkarak-website"
DIR="$REPOS_DIR/aarushkarak-website"

if [ ! -d "$DIR" ]; then
  gh repo clone "$REPO" "$DIR"
fi

cd "$DIR"
git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
git pull origin HEAD 2>&1 | tee -a "$LOG_FILE"

TS="$(date '+%Y-%m-%d %H:%M:%S')"

# Always rewrite AnimatedCounter with timestamp comment
cat > src/components/ui/AnimatedCounter.tsx << 'EOF'
import { useState, useEffect, useRef } from 'react';
import { useInView } from 'react-intersection-observer';

interface AnimatedCounterProps {
  end: number;
  suffix?: string;
  duration?: number;
  label?: string;
}

export function AnimatedCounter({ end, suffix = '', duration = 2000, label }: AnimatedCounterProps) {
  const [count, setCount] = useState(0);
  const { ref, inView } = useInView({ triggerOnce: true, threshold: 0.3 });
  const startedRef = useRef(false);

  useEffect(() => {
    if (!inView || startedRef.current) return;
    startedRef.current = true;

    const startTime = performance.now();

    const animate = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);

      const eased = 1 - Math.pow(1 - progress, 3);
      const current = Math.floor(eased * end);

      setCount(current);

      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        setCount(end);
      }
    };

    requestAnimationFrame(animate);
  }, [inView, end, duration]);

  return (
    <div ref={ref} className="text-center">
      <span className="text-3xl font-bold text-white">{count}{suffix}</span>
      {label && <p className="text-sm text-gray-400 mt-1">{label}</p>}
    </div>
  );
}
EOF

sed -i "1s/^/\/\/ $TS\n/" src/components/ui/AnimatedCounter.tsx

# Always rewrite SEOHead with timestamp
mkdir -p src/components/seo
cat > src/components/seo/SEOHead.tsx << 'EOF'
import { Helmet } from 'react-helmet-async';

interface SEOHeadProps {
  title?: string;
  description?: string;
  path?: string;
}

export function SEOHead({ title, description, path = '' }: SEOHeadProps) {
  const siteName = 'Aarush Karak';
  const fullTitle = title ? `${title} | ${siteName}` : `${siteName} — Software Developer & Spatial Computing`;
  const desc = description || 'Full-stack developer and spatial computing engineer. Building HELIOS, The Coder Bros, and open-source tools.';
  const url = `https://aarushkarak.vercel.app${path}`;

  return (
    <Helmet>
      <title>{fullTitle}</title>
      <meta name="description" content={desc} />
      <meta property="og:title" content={fullTitle} />
      <meta property="og:description" content={desc} />
      <meta property="og:url" content={url} />
      <meta name="twitter:card" content="summary_large_image" />
      <meta name="twitter:title" content={fullTitle} />
      <meta name="twitter:description" content={desc} />
      <link rel="canonical" href={url} />
    </Helmet>
  );
}
EOF

sed -i "1s/^/\/\/ $TS\n/" src/components/seo/SEOHead.tsx

if ! grep -q "react-helmet-async" package.json 2>/dev/null; then
  npm install react-helmet-async 2>&1 | tail -1
fi

has_import=$(grep -c "HelmetProvider" src/main.tsx 2>/dev/null || echo 0)
if [ "$has_import" -eq 0 ]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i "s|import { BrowserRouter }|import { HelmetProvider } from 'react-helmet-async'\nimport { BrowserRouter }|" src/main.tsx 2>/dev/null || true
    sed -i "s|<BrowserRouter>|<HelmetProvider>\n      <BrowserRouter>|" src/main.tsx 2>/dev/null || true
    sed -i "s|</BrowserRouter>|</BrowserRouter>\n    </HelmetProvider>|" src/main.tsx 2>/dev/null || true
  else
    sed -i "s|import { BrowserRouter }|import { HelmetProvider } from 'react-helmet-async'\nimport { BrowserRouter }|" src/main.tsx 2>/dev/null || true
    sed -i "s|<BrowserRouter>|<HelmetProvider>\n      <BrowserRouter>|" src/main.tsx 2>/dev/null || true
    sed -i "s|</BrowserRouter>|</BrowserRouter>\n    </HelmetProvider>|" src/main.tsx 2>/dev/null || true
  fi
fi

for page in HomePage AboutPage ExperiencePage ProjectsPage SkillsPage ContactPage; do
  page_file=$(find src -name "${page}.tsx" -path "*/pages/*" 2>/dev/null | head -1)
  if [ -n "$page_file" ] && ! grep -q "SEOHead" "$page_file" 2>/dev/null; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i "1s/^/import { SEOHead } from '..\/components\/seo\/SEOHead';\n/" "$page_file" 2>/dev/null || true
    else
      sed -i "1s/^/import { SEOHead } from '..\/components\/seo\/SEOHead';\n/" "$page_file" 2>/dev/null || true
    fi
  fi
done

if ! grep -q "lazy\|Suspense" src/App.tsx 2>/dev/null; then
  app_file="src/App.tsx"
  if [ -f "$app_file" ]; then
    content=$(cat "$app_file")
    new_content=""
    while IFS= read -r line; do
      if echo "$line" | grep -q "import.*from.*pages/"; then
        page_name=$(echo "$line" | sed -n 's/.*import \(.*\) from.*pages\/\(.*\)Page.*/\1/p')
        if [ -n "$page_name" ]; then
          new_content="${new_content}import { lazy } from 'react';\n"
          new_content="${new_content}const ${page_name} = lazy(() => import('./pages/${page_name}Page'));\n"
        fi
      else
        new_content="${new_content}${line}\n"
      fi
    done <<< "$content"
    echo "$new_content" > "$app_file"
  fi
fi

git add -A
git diff --staged --quiet || (git commit -m "Update portfolio: $TS [skip ci]" && git push origin HEAD 2>&1 | tee -a "$LOG_FILE" && log "portfolio: Updated and pushed.") || log "portfolio: No changes."

cd "$PIPELINE_DIR"
