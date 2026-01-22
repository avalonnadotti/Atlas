@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ===========================
REM ATLAS - Terraform (bootstrap/deploy)
REM ===========================

REM Sempre executar a partir da pasta onde o .bat está
cd /d "%~dp0"

REM Lista de repos
set REPOS=Pythia Oraculo Mnemos Forge
set GIT_BASE=https://github.com/avalonnadotti

echo ==================================================
echo ATLAS - Atualizando repos e subindo stack
echo Base: %CD%
echo ==================================================
echo.

echo [1/3] Derrubando stack atual (se existir)...
docker compose -p atlas down

echo.
echo [2/3] Sincronizando repos...
for %%R in (%REPOS%) do (
  echo --------------------------------------------------
  echo Repo: %%R

  if exist "%%R\.git" (
    echo - Ja existe. Resetando e atualizando...
    pushd "%%R" >nul

    REM Descarta mudancas locais
    git reset --hard
    REM Remove arquivos nao versionados (opcional, mas recomendado em deploy)
    git clean -fd

    REM Atualiza refs remotas e remove refs antigas
    git fetch --all --prune

    REM Puxa a branch atual (mais seguro do que pull --all)
    git pull

    popd >nul
  ) else (
    echo - Nao existe. Clonando...
    git clone "%GIT_BASE%/%%R" "%%R"
    if errorlevel 1 (
      echo [ERRO] Falha ao clonar %%R. Abortando.
      exit /b 1
    )

    REM Opcional: garantir que o repo recém clonado está limpo e atualizado
    pushd "%%R" >nul
    git reset --hard
    git clean -fd
    git fetch --all --prune
    popd >nul
  )
)

echo.
echo [3/3] Subindo stack...
docker compose -p atlas up -d
if errorlevel 1 (
  echo [ERRO] Falha ao subir containers.
  exit /b 1
)

echo.
echo ==================================================
echo OK - ATLAS atualizado e em execucao.
echo Nginx: http://localhost:8080
echo ==================================================
exit /b 0
