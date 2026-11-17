$listener = New-Object System.Net.HttpListener
$port = 8732
$root = "C:\EXECUTAVEL CENSO 2026\neurotask"
$listener.Prefixes.Add("http://localhost:$port/")
$listener.Start()
Write-Output "SERVING $root on http://localhost:$port/"
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = $ctx.Request.Url.LocalPath.TrimStart('/')
  if ($path -eq "") { $path = "index.html" }
  $file = Join-Path $root $path
  if (Test-Path $file -PathType Leaf) {
    $bytes = [System.IO.File]::ReadAllBytes($file)
    $ctx.Response.StatusCode = 200
    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $mime = switch ($ext) {
      ".html" { "text/html; charset=utf-8" }
      ".css"  { "text/css" }
      ".js"   { "application/javascript" }
      ".xml"  { "application/xml" }
      ".txt"  { "text/plain; charset=utf-8" }
      ".png"  { "image/png" }
      ".jpg"  { "image/jpeg" }
      ".svg"  { "image/svg+xml" }
      default { "text/plain" }
    }
    $ctx.Response.ContentType = $mime
    $ctx.Response.ContentLength64 = $bytes.Length
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.OutputStream.Close()
  } else {
    $ctx.Response.StatusCode = 404
    $ctx.Response.Close()
  }
}
