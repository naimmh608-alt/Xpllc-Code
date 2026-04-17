@echo off
setlocal enabledelayedexpansion

echo =================================================
echo   [>>] Xpllc-Code Windows Auto-Installer
echo   Groq + OpenRouter + Modal Multi-Provider Edition
echo =================================================
echo.
echo   Let's get your settings first!
echo =================================================
echo.

:: Provider Selection
echo   Select API Provider:
echo   1) Groq        (Ultra-fast inference, groq.com)
echo   2) OpenRouter   (Multi-model access, openrouter.ai)
echo   3) Modal        (Serverless GPU inference, modal.com)
echo.
set /p PROVIDER_CHOICE="Choose [1-3] (Default: 1 - Groq): "
if "%PROVIDER_CHOICE%"=="" set PROVIDER_CHOICE=1

if "%PROVIDER_CHOICE%"=="1" (
    set PROVIDER=groq
    set API_BASE=https://api.groq.com/openai/v1
    echo   [OK] Provider: Groq
) else if "%PROVIDER_CHOICE%"=="3" (
    set PROVIDER=modal
    echo   [OK] Provider: Modal
    echo.
    echo   Modal serves OpenAI-compatible APIs from your deployed apps.
    echo   URL format: https://your-workspace--app-name-serve.modal.run
    echo   Deploy first: modal deploy your_app.py
    echo   Docs: https://modal.com/docs/examples/vllm_inference
    echo.
    set /p MODAL_ENDPOINT="Enter your Modal endpoint URL: "
    set API_BASE=!MODAL_ENDPOINT!/v1
) else (
    set PROVIDER=openrouter
    set API_BASE=https://openrouter.ai/api/v1
    echo   [OK] Provider: OpenRouter
)
echo.

:: API Key
if "!PROVIDER!"=="groq" (
    echo   Get your free key at: https://console.groq.com/keys
    set /p API_KEY="Enter your Groq API Key (gsk_...): "
) else if "!PROVIDER!"=="modal" (
    echo   Modal uses token-based auth. Pass any key or press Enter for 'no-key'.
    echo   Setup tokens: modal token set --token-id ^<id^> --token-secret ^<secret^>
    echo   Get tokens at: https://modal.com/settings
    set /p API_KEY="Enter API Key (or press Enter for no-key): "
    if "!API_KEY!"=="" set API_KEY=no-key
) else (
    set /p API_KEY="Enter your OpenRouter API Key (sk-or-...): "
)
echo.

:: Model Selection
if "!PROVIDER!"=="groq" (
    echo   Available Groq Models:
    echo   -----------------------------------------
    echo   -- Meta Llama --
    echo   1^) llama-3.1-8b-instant              (560 T/s, 131K ctx^)
    echo   2^) llama-3.3-70b-versatile            (280 T/s, 131K ctx^)
    echo   3^) meta-llama/llama-4-scout-17b-16e-instruct (750 T/s, vision^)
    echo   -- OpenAI OSS --
    echo   4^) openai/gpt-oss-120b                (500 T/s, 131K ctx^)
    echo   5^) openai/gpt-oss-20b                 (1000 T/s, 131K ctx^)
    echo   -- Qwen --
    echo   6^) qwen/qwen3-32b                     (400 T/s, 131K ctx^)
    echo   -- Compound Systems --
    echo   7^) groq/compound                      (450 T/s, built-in tools^)
    echo   8^) groq/compound-mini                  (450 T/s, built-in tools^)
    echo   -----------------------------------------
    echo   9^) Custom Model ID
    echo.
    set /p MODEL_CHOICE="Choose a number (Default: 2 - llama-3.3-70b): "
    if "!MODEL_CHOICE!"=="" set MODEL_CHOICE=2

    if "!MODEL_CHOICE!"=="1" set MODEL_NAME=llama-3.1-8b-instant
    if "!MODEL_CHOICE!"=="2" set MODEL_NAME=llama-3.3-70b-versatile
    if "!MODEL_CHOICE!"=="3" set MODEL_NAME=meta-llama/llama-4-scout-17b-16e-instruct
    if "!MODEL_CHOICE!"=="4" set MODEL_NAME=openai/gpt-oss-120b
    if "!MODEL_CHOICE!"=="5" set MODEL_NAME=openai/gpt-oss-20b
    if "!MODEL_CHOICE!"=="6" set MODEL_NAME=qwen/qwen3-32b
    if "!MODEL_CHOICE!"=="7" set MODEL_NAME=groq/compound
    if "!MODEL_CHOICE!"=="8" set MODEL_NAME=groq/compound-mini
    if "!MODEL_CHOICE!"=="9" (
        echo.
        echo   Enter any model ID from https://console.groq.com/docs/models
        set /p MODEL_NAME="Enter custom model ID: "
    )
) else if "!PROVIDER!"=="modal" (
    echo   Available Modal Models (deploy these via vLLM/SGLang^):
    echo   -----------------------------------------
    echo   1^) google/gemma-4-26B-A4B-it             (Fast MoE, vision^)
    echo   2^) meta-llama/Llama-3.3-70B-Instruct      (Strong general purpose^)
    echo   3^) meta-llama/Llama-3.1-8B-Instruct       (Fast and lightweight^)
    echo   4^) mistralai/Mistral-Small-24B-Instruct-2501 (Efficient^)
    echo   5^) Qwen/Qwen3-32B                         (Multilingual^)
    echo   6^) openai/gpt-oss-120b                     (Large OSS model^)
    echo   -----------------------------------------
    echo   7^) Custom Model ID
    echo.
    set /p MODEL_CHOICE="Choose a number (Default: 1 - gemma-4^): "
    if "!MODEL_CHOICE!"=="" set MODEL_CHOICE=1

    if "!MODEL_CHOICE!"=="1" set MODEL_NAME=google/gemma-4-26B-A4B-it
    if "!MODEL_CHOICE!"=="2" set MODEL_NAME=meta-llama/Llama-3.3-70B-Instruct
    if "!MODEL_CHOICE!"=="3" set MODEL_NAME=meta-llama/Llama-3.1-8B-Instruct
    if "!MODEL_CHOICE!"=="4" set MODEL_NAME=mistralai/Mistral-Small-24B-Instruct-2501
    if "!MODEL_CHOICE!"=="5" set MODEL_NAME=Qwen/Qwen3-32B
    if "!MODEL_CHOICE!"=="6" set MODEL_NAME=openai/gpt-oss-120b
    if "!MODEL_CHOICE!"=="7" (
        echo.
        echo   Enter the HuggingFace model ID you deployed on Modal
        set /p MODEL_NAME="Enter custom model ID: "
    )
) else (
    echo Fetching live list of FREE OpenRouter models...
    powershell -NoProfile -Command "$response = Invoke-RestMethod -Uri 'https://openrouter.ai/api/v1/models'; $freeModels = $response.data | Where-Object { $_.id -like '*:free' }; $i = 1; foreach ($model in $freeModels) { Write-Host ($i.ToString() + ') ' + $model.id); $i++ }; Write-Host ($i.ToString() + ') Custom (Type your own)')" > "%TEMP%\models.txt"
    echo.
    type "%TEMP%\models.txt"
    echo.
    set /p MODEL_CHOICE="Choose a number (Default: 1): "
    if "!MODEL_CHOICE!"=="" set MODEL_CHOICE=1

    :: Extract the chosen model string from the file
    for /f "tokens=1,* delims=) " %%A in ('type "%TEMP%\models.txt" ^| findstr /b "!MODEL_CHOICE!)"') do (
        set MODEL_NAME=%%B
    )

    if "!MODEL_NAME!"=="Custom (Type your own)" (
        set /p MODEL_NAME="Enter custom model name: "
    )
)

if "!MODEL_NAME!"=="" set MODEL_NAME=llama-3.3-70b-versatile

echo.
echo [OK] Provider : !PROVIDER!
echo [OK] Model    : !MODEL_NAME!
echo [OK] API Base : !API_BASE!
echo.
pause

echo.
echo =================================================
echo   [>>] Installing OpenClaude...
echo =================================================
echo.

call npm init -y
call npm install @gitlawb/openclaude

echo.
echo [3/3] Generating start.bat launcher script...

(
echo @echo off
echo set CLAUDE_CODE_USE_OPENAI=1
echo set OPENAI_API_KEY=%API_KEY%
echo set OPENAI_BASE_URL=!API_BASE!
echo set OPENAI_MODEL=!MODEL_NAME!
echo set ANTHROPIC_API_KEY=
echo echo Booting Xpllc-Code with !MODEL_NAME! via !PROVIDER!...
echo npx openclaude %%*
) > start.bat

echo.
echo =================================================
echo   [DONE] Setup Complete!
echo.
echo   Provider: !PROVIDER!
echo   Model   : !MODEL_NAME!
echo.
echo   To run your AI assistant anytime, just double
echo   click 'start.bat' or type: .\start.bat
echo =================================================
echo.
pause
