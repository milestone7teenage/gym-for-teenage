Add-Type -AssemblyName System.Drawing
$paths = @(
  'E:\IOSapp\gym_log\dasads\sadfdf13.png',
  'E:\IOSapp\gym_log\assets\app_icon.png',
  'E:\IOSapp\gym_log\web\favicon.png',
  'E:\IOSapp\gym_log\web\icons\Icon-192.png',
  'E:\IOSapp\gym_log\web\icons\Icon-512.png',
  'E:\IOSapp\gym_log\web\icons\Icon-maskable-192.png',
  'E:\IOSapp\gym_log\web\icons\Icon-maskable-512.png'
)
foreach ($p in $paths) {
  if (Test-Path -LiteralPath $p) {
    $i = [System.Drawing.Image]::FromFile($p)
    Write-Output ("{0}: {1}x{2}" -f (Split-Path $p -Leaf), $i.Width, $i.Height)
    $i.Dispose()
  } else {
    Write-Output ("MISSING: {0}" -f $p)
  }
}
