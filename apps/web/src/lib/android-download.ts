// Android APK download — metadata lives HERE (in the app), not in .env.
// On every release, update these four values with the ones printed by
// scripts/release-apk.ps1 (version, size, SHA-256). The file name only
// changes if the Flutter flavor/output name changes.
const APK_META = {
  version: "1.0.1",
  fileName: "app-user-release.apk",
  sizeBytes: 190847040,
  sha256: "fa6f5fbdb4b506c1ba6b645a4594411f74e7ccf7ac6e0934c2b5eabfc3a2787a",
};

function clean(value: string | undefined, fallback: string): string {
  return value && value.trim().length > 0 ? value.trim() : fallback;
}

// Only the URL comes from .env (the stable /releases/latest/download/ link).
export const androidDownload = {
  url: clean(process.env.NEXT_PUBLIC_ANDROID_APK_URL, ""),
  version: APK_META.version,
  fileName: APK_META.fileName,
  sizeBytes: APK_META.sizeBytes,
  sha256: APK_META.sha256.toLowerCase(),
};

export const hasAndroidDownload = androidDownload.url.length > 0;

export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return "0 MB";
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export const androidDownloadSizeLabel = formatBytes(androidDownload.sizeBytes);
