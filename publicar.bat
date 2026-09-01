@echo off
REM ---------------------------------------------------------------------------
REM Publica o Radar no GitHub Pages.
REM
REM O que faz: comita e envia APENAS o index.html deste repositorio.
REM Quem gera o index.html: a tarefa semanal do Claude, toda segunda 8h55, que
REM copia o Radar-Consolidado.html da pasta BASE GESTAO CLAUDE para ca.
REM
REM Por que este script existe: o Claude consegue escrever o arquivo na pasta,
REM mas nao consegue fazer push - nao tem credencial do GitHub, e nao deve ter.
REM Este script roda no Windows e usa a credencial que ja esta configurada na
REM sua maquina. Nenhum token fica escrito aqui.
REM
REM Uso: dar duplo clique, ou agendar no Agendador de Tarefas do Windows para
REM segunda-feira as 9h10 (depois da tarefa do Claude, que roda 8h55).
REM
REM Atencao: adiciona SO o index.html de proposito. O .gitignore deste repo esta
REM salvo com quebra de linha CRLF e o git o marca como modificado para sempre;
REM um "git add -A" geraria um commit inutil toda semana.
REM ---------------------------------------------------------------------------

cd /d "%~dp0"

echo.
echo === Publicando Radar no GitHub Pages ===
echo Pasta: %CD%
echo.

REM Trava esquecida por processo git interrompido (ex.: GitHub Desktop fechado
REM no meio de uma operacao). Se existir, impede qualquer commit.
if exist ".git\index.lock" (
    echo Removendo trava antiga do git ^(.git\index.lock^)...
    del /q ".git\index.lock"
)

if not exist "index.html" (
    echo ERRO: index.html nao encontrado nesta pasta.
    echo A tarefa semanal do Claude deveria ter criado o arquivo.
    goto :fim
)

git add index.html
if errorlevel 1 (
    echo ERRO: falha no git add.
    goto :fim
)

REM Se o conteudo nao mudou, nao ha o que comitar - e isso nao e erro.
git diff --cached --quiet
if not errorlevel 1 (
    echo Nada mudou no index.html. Nada a publicar.
    goto :fim
)

for /f "tokens=1-3 delims=/ " %%a in ("%DATE%") do set HOJE=%%c-%%b-%%a
git commit -m "Radar do Mercado: atualizacao de %HOJE%"
if errorlevel 1 (
    echo ERRO: falha no git commit.
    goto :fim
)

git push origin main
if errorlevel 1 (
    echo.
    echo ERRO no push. Causas comuns:
    echo  - credencial do GitHub expirada: abra o GitHub Desktop e faca login
    echo  - sem internet
    echo O commit ficou salvo localmente; basta rodar de novo depois.
    goto :fim
)

echo.
echo Publicado. O site atualiza em cerca de um minuto:
echo https://berlangaconsultoria-jpg.github.io/Radar-Automotivo/
echo.

:fim
echo.
pause
