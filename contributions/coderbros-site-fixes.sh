#!/usr/bin/env bash
set -euo pipefail

REPO="3ni8ma/TheCoderBros-Website"
DIR="$REPOS_DIR/TheCoderBros-Website"

if [ ! -d "$DIR" ]; then
  gh repo clone "$REPO" "$DIR"
fi

cd "$DIR"
git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
git remote get-url origin 2>/dev/null && git pull origin HEAD 2>&1 | tee -a "$LOG_FILE" || log "coderbros: No remote configured, skipping pull"

TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

cat > src/app/loading.tsx << 'EOF'
export default function Loading() {
  return (
    <div className="flex items-center justify-center min-h-screen bg-[#0a0a0a]">
      <div className="flex flex-col items-center gap-4">
        <div className="w-8 h-8 border-2 border-purple-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-gray-400 text-sm">Loading...</p>
      </div>
    </div>
  );
}
EOF

sed -i "1s/^/\/\/ Updated: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/app/loading.tsx

cat > src/app/error.tsx << 'EOF'
"use client";

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div className="flex items-center justify-center min-h-screen bg-[#0a0a0a]">
      <div className="text-center max-w-md px-8">
        <h2 className="text-2xl font-bold text-white mb-2">Something went wrong</h2>
        <p className="text-gray-400 mb-6">
          An unexpected error occurred. Please try again.
        </p>
        <button
          onClick={reset}
          className="px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors"
        >
          Try again
        </button>
      </div>
    </div>
  );
}
EOF

sed -i "1s/^/\/\/ Updated: $(date '+%Y-%m-%d %H:%M:%S')\n/" src/app/error.tsx

cat > "src/app/courses/[slug]/page.tsx" << 'PAGEEOF'
import { courses } from "@/lib/data/courses";
import { notFound } from "next/navigation";
import Slideshow from "@/components/courses/slideshow";

interface CoursePageProps {
  params: Promise<{ slug: string }>;
}

export async function generateStaticParams() {
  return courses.map((course) => ({ slug: course.slug }));
}

export default async function CoursePage({ params }: CoursePageProps) {
  const { slug } = await params;
  const course = courses.find((c) => c.slug === slug);

  if (!course) {
    notFound();
  }

  return (
    <div className="min-h-screen bg-background pt-20">
      <Slideshow course={course} />
    </div>
  );
}
PAGEEOF

sed -i "1s/^/\/\/ Updated: $(date '+%Y-%m-%d %H:%M:%S')\n/" "src/app/courses/[slug]/page.tsx"

echo -e "\n# Pipeline timestamp $(date +%s)" >> .gitignore

git add -A
git diff --staged --quiet || (git commit -m "Update coderbros site: $(date '+%Y-%m-%d %H:%M') [skip ci]" && git push origin HEAD 2>&1 | tee -a "$LOG_FILE" && log "coderbros: Updated and pushed.") || log "coderbros: No changes."

cd "$PIPELINE_DIR"
