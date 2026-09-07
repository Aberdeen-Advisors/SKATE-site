@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Publish SKATE Site to GitHub
cd /d "%~dp0"

set "REMOTE=https://github.com/Aberdeen-Advisors/SKATE-site.git"
set "BRANCH=main"

echo.
echo   SKATE SITE PUBLISHER
echo   ====================
echo   Coffee in. Context out. Site up.
echo.

where git >nul 2>nul
if errorlevel 1 (
  echo ERROR: Git is not installed or is not available on PATH.
  echo Install Git for Windows from https://git-scm.com/download/win and run this file again.
  goto :failed
)

for %%F in (
  index.html
  favicon.png
  skateboard.png
  skateboard-3d.js
  THIRD-PARTY-NOTICES.txt
  README.md
  vercel.json
  .gitignore
  .vercelignore
  publish-to-github.bat
) do (
  if not exist "%%F" (
    echo ERROR: Required file is missing: %%F
    goto :failed
  )
)

if /I "%~1"=="--check" (
  echo CHECK PASSED: Every approved upload file is present.
  exit /b 0
)

if not exist ".git\" (
  echo Creating the local repository...
  git init
  if errorlevel 1 goto :git_failed
)

set "CURRENT_REMOTE="
for /f "delims=" %%R in ('git remote get-url origin 2^>nul') do set "CURRENT_REMOTE=%%R"
if not defined CURRENT_REMOTE (
  git remote add origin "%REMOTE%"
  if errorlevel 1 goto :git_failed
) else if /I not "!CURRENT_REMOTE!"=="%REMOTE%" (
  echo ERROR: This folder already points to a different GitHub repository:
  echo !CURRENT_REMOTE!
  echo Nothing was uploaded. Fix the remote or use a fresh copy of this folder.
  goto :failed
)

git branch -M "%BRANCH%"
if errorlevel 1 goto :git_failed

git add -- index.html favicon.png skateboard.png skateboard-3d.js THIRD-PARTY-NOTICES.txt README.md vercel.json .gitignore .vercelignore publish-to-github.bat
if errorlevel 1 goto :git_failed

git diff --cached --quiet
if errorlevel 1 (
  git config user.name >nul 2>nul
  if errorlevel 1 (
    set /p "GIT_NAME=Your name for the GitHub commit: "
    if not defined GIT_NAME goto :identity_missing
    git config user.name "!GIT_NAME!"
  )
  git config user.email >nul 2>nul
  if errorlevel 1 (
    set /p "GIT_EMAIL=Your GitHub email: "
    if not defined GIT_EMAIL goto :identity_missing
    git config user.email "!GIT_EMAIL!"
  )
  git commit -m "Update SKATE site"
  if errorlevel 1 goto :git_failed
) else (
  echo No changed site files to commit. Checking GitHub anyway...
)

echo.
echo Uploading to %REMOTE%...
git push -u origin "%BRANCH%"
if errorlevel 1 (
  echo.
  echo The upload did not complete. If the GitHub repository already contains
  echo a README or another first commit, empty it or clone it before retrying.
  echo Your local site files are safe and unchanged.
  goto :failed
)

echo.
echo SUCCESS: SKATE is on GitHub.
echo https://github.com/Aberdeen-Advisors/SKATE-site
echo.
echo Next: import that repository at https://vercel.com/new
pause
exit /b 0

:identity_missing
echo ERROR: A Git commit name and email are required. Nothing was uploaded.
goto :failed

:git_failed
echo ERROR: Git could not finish the requested step. Nothing outside this site folder was staged.

:failed
echo.
pause
exit /b 1
