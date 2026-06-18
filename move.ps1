New-Item -ItemType Directory -Force apps/web
New-Item -ItemType Directory -Force packages
$itemsToMove = "src", "public", ".next", "components.json", "eslint.config.mjs", "next-env.d.ts", "next.config.ts", "package.json", "postcss.config.mjs", "tsconfig.json", "tsconfig.tsbuildinfo"
foreach ($item in $itemsToMove) {
    if (Test-Path $item) {
        Move-Item -Path $item -Destination apps/web/ -Force
    }
}
