@echo off
setlocal enabledelayedexpansion
REM ---------------------------------------------------------------------------
REM Publica o Radar no GitHub Pages.
REM
REM O QUE FAZ
REM Comita e envia APENAS o index.html deste repositorio. E o mesmo que abrir o
REM GitHub Desktop e clicar em "Commit to main" e depois "Push origin" - so que
REM sem abrir programa nenhum, o que permite agendar.
REM
REM QUEM GERA O index.html
REM A tarefa semanal do Claude, toda segunda 8h55, copia o Radar-Consolidado.html
REM da pasta BASE GESTAO CLAUDE para ca com o nome index.html.
REM
REM POR QUE ESTE SCRIPT EXISTE
REM O Claude escreve o arquivo na pasta, mas nao consegue fazer push: nao tem
REM credencial do GitHub, e nao deve ter. Este script roda no Windows e usa a
REM credencial que ja esta na sua maquina. Nenhum token fica escrito aqui.
REM
REM COMO USAR
REM  - Manual: duplo clique. Mostra o resultado e espera voce fechar.
REM  - Agendado: chamar com o parametro /auto
REM      publicar.bat /auto
REM    Nesse modo NAO espera tecla nenhuma (senao o Agendador do Windows ficaria
REM    travado) e grava o resultado em publicar.log.
REM
REM SOBRE O git NAO ESTAR NO PATH
REM Em 01/09/2026 o agendamento falhou com "git no se reconoce como un comando".
REM O git desta maquina veio embutido no GitHub Desktop, que nao o registra no
REM PATH do Windows. Por isso o script procura o executavel em varios lugares
REM antes de desistir. Se um dia instalar o Git for Windows, ele passa a ser
REM encontrado direto pelo PATH e nada aqui precisa mudar.
REM
REM ATENCAO: adiciona SO o index.html, de proposito. Um "git add -A" arrastaria
REM alteracoes que nao tem nada a ver com a publicacao do site.
REM ---------------------------------------------------------------------------

cd /d "%~dp0"
set MODO_AUTO=0
if /i "%~1"=="/auto" set MODO_AUTO=1

if "%MODO_AUTO%"=="1" (
    call :publicar >> "publicar.log" 2>&1
    exit /b
)
call :publicar
echo.
pause
exit /b


:localizar_git
REM Deixa em GIT o comando a usar. Vazio = nao encontrado.
set "GIT="
where git >nul 2>&1
if not errorlevel 1 (
    set "GIT=git"
    goto :eof
)
for %%C in (
    "%ProgramFiles%\Git\cmd\git.exe"
    "%ProgramFiles(x86)%\Git\cmd\git.exe"
    "%LOCALAPPDATA%\Programs\Git\cmd\git.exe"
) do if not defined GIT if exist %%C set "GIT=%%C"
REM GitHub Desktop guarda o git numa pasta com a versao no nome (app-3.x.y)
if not defined GIT for /d %%D in ("%LOCALAPPDATA%\GitHubDesktop\app-*") do (
    if exist "%%D\resources\app\git\cmd\git.exe" set "GIT="%%D\resources\app\git\cmd\git.exe""
)
goto :eof


:publicar
echo.
echo ============================================================
echo Publicando Radar no GitHub Pages
echo Data: %DATE% %TIME%
echo Pasta: %CD%
echo ============================================================

call :localizar_git
if not defined GIT (
    echo ERRO: nao encontrei o git nesta maquina.
    echo Procurei no PATH, em Program Files e dentro do GitHub Desktop.
    echo Solucao: instalar o Git for Windows em https://git-scm.com/download/win
    echo Durante a instalacao, aceitar a opcao que adiciona o git ao PATH.
    exit /b 1
)
echo git encontrado: %GIT%

REM Trava esquecida por processo git interrompido. Enquanto ela existir, nenhum
REM commit funciona - nem pelo GitHub Desktop.
if exist ".git\index.lock" (
    echo Removendo trava antiga do git ^(.git\index.lock^)...
    del /q ".git\index.lock"
)

if not exist "index.html" (
    echo ERRO: index.html nao encontrado nesta pasta.
    echo A tarefa semanal do Claude deveria ter criado o arquivo.
    exit /b 1
)

%GIT% add index.html
if errorlevel 1 (
    echo ERRO: falha no git add.
    exit /b 1
)

REM Se o conteudo nao mudou, nao ha o que publicar - e isso nao e erro.
%GIT% diff --cached --quiet
if not errorlevel 1 (
    echo Nada mudou no index.html. Nada a publicar.
    exit /b 0
)

for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do set HOJE=%%c-%%b-%%a
%GIT% commit -m "Radar do Mercado: atualizacao de %HOJE%"
if errorlevel 1 (
    echo ERRO: falha no git commit.
    exit /b 1
)

%GIT% push origin main
if errorlevel 1 (
    echo.
    echo ERRO no push. Causas comuns:
    echo  - credencial do GitHub nao acessivel para este processo: abra o GitHub
    echo    Desktop, confirme que esta logado, e rode este script manualmente
    echo    uma vez com duplo clique para gravar a credencial
    echo  - sem internet
    echo O commit ficou salvo localmente; basta rodar de novo depois.
    exit /b 1
)

echo.
echo PUBLICADO. O site atualiza em cerca de um minuto:
echo https://berlangaconsultoria-jpg.github.io/Radar-Automotivo/
exit /b 0
