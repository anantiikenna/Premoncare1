const DEFAULTS = {
  version: "1.0.0",
  fileName: "app-user-release.apk",
  sizeBytes: 190683196,
  sha256: "6208c0c09b1ec835610bbfe96d51e4ba42e32e9fa381a26a9bc32c20bbc7469c",
};

function clean(value: string | undefined, fallback: string): string {
  return value && value.trim().length > 0 ? value.trim() : fallback;
}

export const androidDownload = {
  url: clean(process.env.NEXT_PUBLIC_ANDROID_APK_URL, ""),
  version: clean(process.env.NEXT_PUBLIC_ANDROID_APK_VERSION, DEFAULTS.version),
  fileName: clean(process.env.NEXT_PUBLIC_ANDROID_APK_FILENAME, DEFAULTS.fileName),
  sizeBytes: Number(clean(process.env.NEXT_PUBLIC_ANDROID_APK_SIZE_BYTES, String(DEFAULTS.sizeBytes))),
  sha256: clean(process.env.NEXT_PUBLIC_ANDROID_APK_SHA256, DEFAULTS.sha256).toLowerCase(),
};

export const hasAndroidDownload = androidDownload.url.length > 0;

export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes <= 0) return "0 MB";
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export const androidDownloadSizeLabel = formatBytes(androidDownload.sizeBytes);
