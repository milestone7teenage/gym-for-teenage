Add-Type -AssemblyName System.Drawing

$sourcePath = 'E:\IOSapp\gym_log\dasads\sadfdf13.png'
$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)

# Функция для создания квадратной иконки с кадрированием по центру
function New-AppIcon {
  param($size, $outputPath)
  
  $newImage = New-Object System.Drawing.Bitmap($size, $size)
  $graphics = [System.Drawing.Graphics]::FromImage($newImage)
  $graphics.Clear([System.Drawing.Color]::Black)
  
  # Вычисляем область кадрирования (центр)
  $minDim = [Math]::Min($sourceImage.Width, $sourceImage.Height)
  $x = ($sourceImage.Width - $minDim) / 2
  $y = ($sourceImage.Height - $minDim) / 2
  
  $srcRect = New-Object System.Drawing.Rectangle($x, $y, $minDim, $minDim)
  $destRect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
  
  $graphics.DrawImage($sourceImage, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
  $graphics.Dispose()
  $newImage.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
  $newImage.Dispose()
  
  Write-Output "Created: $outputPath ($size x $size)"
}

# Создаём все необходимые иконки
New-AppIcon -size 16 -outputPath 'E:\IOSapp\gym_log\web\favicon.png'
New-AppIcon -size 192 -outputPath 'E:\IOSapp\gym_log\web\icons\Icon-192.png'
New-AppIcon -size 512 -outputPath 'E:\IOSapp\gym_log\web\icons\Icon-512.png'
New-AppIcon -size 192 -outputPath 'E:\IOSapp\gym_log\web\icons\Icon-maskable-192.png'
New-AppIcon -size 512 -outputPath 'E:\IOSapp\gym_log\web\icons\Icon-maskable-512.png'
New-AppIcon -size 1024 -outputPath 'E:\IOSapp\gym_log\assets\app_icon.png'

$sourceImage.Dispose()
Write-Output "All icons created successfully!"