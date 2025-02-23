/*
@echo off & cls

timeout /T 3 /nobreak >nul

for /F %%i in ('dir /B /S ^"%WinDir%\Microsoft.NET\Framework\vbc.exe^"') do set "vbc=%%i" && echo %%i
if /i "%vbc%"=="" cls & echo This script needs the Microsoft .NET Framework & pause & Exit

set /A randNum=%random%
findstr "'VB" "%~f0" | findstr /V "This line should be skipped"> "%tmp%\%~n0_%randNum%.vb"
%vbc% /nologo /out:"%tmp%\%~n0_%randNum%.exe" "%tmp%\%~n0_%randNum%.vb"
"%tmp%\%~n0_%randNum%.exe"

del "%tmp%\%~n0_%randNum%.vb" >nul 2>&1
del "%tmp%\%~n0_%randNum%.exe" >nul 2>&1

exit
*/

Imports System.Windows.Forms 'VB
Imports System.Drawing 'VB
Module ModulePrintscreen 'VB
    Sub Main() 'VB
        Dim MaDate As String = Format(Now, "yyyyMMddHHmmss") 'VB
        Dim screenBounds As Rectangle = Screen.PrimaryScreen.Bounds 'VB
        Using bitmap As New Bitmap(screenBounds.Width, screenBounds.Height) 'VB
            Using g As Graphics = Graphics.FromImage(bitmap) 'VB
                g.CopyFromScreen(Point.Empty, Point.Empty, screenBounds.Size) 'VB
                bitmap.Save(MaDate & ".png", System.Drawing.Imaging.ImageFormat.Png) 'VB
            End Using 'VB
        End Using 'VB
    End Sub 'VB
End Module 'VB
