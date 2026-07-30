@echo off
rem === Set up the subsidy / tax checker on this PC ===
rem After copying this folder to a PC, double-click this file.
chcp 65001 >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
