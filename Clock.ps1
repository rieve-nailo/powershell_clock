 # Run it with: powershell -ExecutionPolicy Bypass -File .\Clock.ps1
 # Windows has scripts disabled by default, probably better security to keep it that way
 
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
$clockForm = New-Object System.Windows.Forms.Form
$clockForm.Text = 'Basic Clock'
$clockForm.ClientSize = New-Object System.Drawing.Size(620, 660) # Window size, added 200 from the copilot version
$clockForm.MinimumSize = New-Object System.Drawing.Size(500, 540) # Size of the clock face, added 200 from the copilot version
$clockForm.StartPosition = 'CenterScreen'
$clockForm.BackColor = [System.Drawing.Color]::FromArgb(24, 29, 38)
$clockForm.GetType().GetProperty('DoubleBuffered', [Reflection.BindingFlags]'Instance,NonPublic').SetValue($clockForm, $true, $null)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 40

$clockForm.Add_Paint({
	param($sender, $e)
	$g = $e.Graphics
	$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
	$diameter = [Math]::Max(80, [Math]::Min($sender.ClientSize.Width - 48, $sender.ClientSize.Height - 48))
	$cx = $sender.ClientSize.Width / 2.0
	$cy = $sender.ClientSize.Height / 2.0
	$r = $diameter / 2.0
	$faceRect = New-Object System.Drawing.RectangleF ([single]($cx - $r)), ([single]($cy - $r)), ([single]$diameter), ([single]$diameter)
	$faceBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(247, 245, 236))
	$g.FillEllipse($faceBrush, $faceRect)
	$faceBrush.Dispose()

	$rimPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(76, 178, 196)), 5
	$g.DrawEllipse($rimPen, $faceRect)
	$rimPen.Dispose()

	$tickPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(55, 65, 75)), 2
	$majorPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(31, 42, 52)), 4
	for ($i = 0; $i -lt 60; $i++) {
		$angle = ($i * 6 - 90) * [Math]::PI / 180
		$outer = $r * 0.91
		$inner = if (($i % 5) -eq 0) { $r * 0.78 } else { $r * 0.86 }
		$pen = if (($i % 5) -eq 0) { $majorPen } else { $tickPen }
		$p1 = New-Object System.Drawing.PointF ([single]($cx + [Math]::Cos($angle) * $inner)), ([single]($cy + [Math]::Sin($angle) * $inner))
		$p2 = New-Object System.Drawing.PointF ([single]($cx + [Math]::Cos($angle) * $outer)), ([single]($cy + [Math]::Sin($angle) * $outer))
		$g.DrawLine($pen, $p1, $p2)
	}
	$tickPen.Dispose()
	$majorPen.Dispose()

	# This section draws the numbers on the clock face
	# Initial version had a bug where the numbers were not centered properly, fixed by adjusting the rectangle for drawing text
	$numberFont = New-Object System.Drawing.Font('Segoe UI', [single]([Math]::Max(10, $r * 0.12)), [System.Drawing.FontStyle]::Bold)
	$numberBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(35, 46, 56))
	$format = New-Object System.Drawing.StringFormat
	$format.Alignment = [System.Drawing.StringAlignment]::Center
	$format.LineAlignment = [System.Drawing.StringAlignment]::Center
	# initial version of the loop for drawing numbers, commented out because it did not center the numbers correctly
	#for ($n = 1; $n -le 12; $n++) {
	#	$angle = ($n * 30 - 90) * [Math]::PI / 180
	#	$nr = $r * 0.66
	#	$textRect = New-Object System.Drawing.RectangleF ([single]($cx + [Math]::Cos($angle) * $nr - $r * 0.12)), ([single]($cy + [Math]::Sin($angle) * $nr - $r * 0.12)), ([single]($r * 0.24)), ([single]($r * 0.24))
	#	$g.DrawString([string]$n, $numberFont, $numberBrush, $textRect, $format)
	#}
	# Updated version of the loop for drawing numbers, now centers the numbers correctly
	for ($n = 1; $n -le 12; $n++) {
		$angle = ($n * 30 - 90) * [Math]::PI / 180
		$nr = $r * 0.66

		$text = [string]$n
		$size = $g.MeasureString($text, $numberFont)

		$x = $cx + [Math]::Cos($angle) * $nr - ($size.Width / 2)
		$y = $cy + [Math]::Sin($angle) * $nr - ($size.Height / 2)

		$g.DrawString($text, $numberFont, $numberBrush,
			[single]$x, [single]$y)
	}
	$format.Dispose()
	$numberBrush.Dispose()
	$numberFont.Dispose()

	$now = Get-Date
	$hands = @(
		@{ Angle = (($now.Hour % 12) + $now.Minute / 60.0 + $now.Second / 3600.0) * 30 - 90; Length = $r * 0.48; Width = 7; Color = [System.Drawing.Color]::FromArgb(35, 46, 56) },
		@{ Angle = ($now.Minute + $now.Second / 60.0) * 6 - 90; Length = $r * 0.68; Width = 5; Color = [System.Drawing.Color]::FromArgb(35, 46, 56) },
		@{ Angle = ($now.Second + $now.Millisecond / 1000.0) * 6 - 90; Length = $r * 0.78; Width = 2; Color = [System.Drawing.Color]::FromArgb(222, 83, 75) }
	)
	foreach ($hand in $hands) {
		$a = $hand.Angle * [Math]::PI / 180
		$pen = New-Object System.Drawing.Pen ($hand.Color), ([single]$hand.Width)
		$pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
		$pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
		$end = New-Object System.Drawing.PointF ([single]($cx + [Math]::Cos($a) * $hand.Length)), ([single]($cy + [Math]::Sin($a) * $hand.Length))
		$g.DrawLine($pen, [System.Drawing.PointF]::new([single]$cx, [single]$cy), $end)
		$pen.Dispose()
	}
	$hubBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(222, 83, 75))
	$g.FillEllipse($hubBrush, [single]($cx - 6), [single]($cy - 6), [single]12, [single]12)
	$hubBrush.Dispose()
})

$timer.Add_Tick({ $clockForm.Invalidate() })
$clockForm.Add_Shown({ $timer.Start() })
$clockForm.Add_FormClosed({ $timer.Stop(); $timer.Dispose() })
[System.Windows.Forms.Application]::Run($clockForm)
