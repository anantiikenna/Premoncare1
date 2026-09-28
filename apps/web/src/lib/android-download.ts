const DEFAULTS = {
  version: "1.0.0",
  fileName: "app-user-release.apk",
  sizeBytes: 190683196,
  sha256: "6208c0c09b1ec835610bbfe96d51e4ba42e32e9fa381a26a9bc32c20bbc7469c",
};

function env(key: string, fallback: string): string {
  const value = process.env[key];
  return value && value.trim().length > 0 ? value.trim() : fallback;
}

export const androidDownload = {
  url: env("NEXT_PUBLIC_ANDROID_APK_URL", ""),
  version: env("NEXT_PUBLIC_ANDROID_APK_VERSION", DEFAULTS.version),
  fileName: env("NEXT_PUBLIC_ANDROID_APK_FILENAME", DEFAULTS.fileName),
  sizeBytes: Number(env("NEXT_PUBLIC_ANDROID_APK_SIZE_BYTES", String(DEFAULTS.sizeBytes))),
  sha256: env("NEXT_PUBLIC_ANDROID_APK_SHA256", DEFAULTS.sha256).toLowerCase(),
};

export const hasAndroidDownload = androidDownload.url.length > 0;

export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return "0 MB";
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export const androidDownloadSizeLabel = formatBytes(androidDownload.sizeBytes);
