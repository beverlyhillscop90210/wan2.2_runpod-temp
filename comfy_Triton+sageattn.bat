@echo off
setlocal

echo Checking if Visual Studio Build Tools (cl.exe) is in PATH...

@REM Step 1: Use 'where' to find cl.exe in the system PATH
where cl.exe >nul 2>nul

@REM Step 2: Check if 'where' command succeeded
if %errorlevel% EQU 0 (
    echo Visual Studio Build Tools is available in PATH!
    for /f "delims=" %%A in ('where cl.exe') do echo Found: %%A
) else (
    echo cl.exe not found in PATH.
    echo You may need to run "VsDevCmd.bat" or install MS Visual Studio Build Tools.
    echo Download from: https://visualstudio.microsoft.com/visual-cpp-build-tools/
    pause
    exit /b 1
)

echo.
echo All MSVC checks passed successfully.
echo Next step: Install Comfy and a Venv for it

@REM ------------------------------------------------------------------------------------------------
@REM Installing ComfyUI and a Venv within it
echo Installing ComfyUI in C:\Users\RAIIN Studios\Documents\Comfy_Blackwell\Comfy_new

cd /d "C:\Users\RAIIN Studios\Documents\Comfy_Blackwell\Comfy_new"
git clone https://github.com/comfyanonymous/ComfyUI
cd ComfyUI
setlocal enabledelayedexpansion

echo.
echo From Comfy github page: "Python 3.13 is supported but using 3.12 is recommended because some custom nodes and their dependencies might not support it yet."
echo.

@REM Step 1: Check for Python 3.12.3 specifically
set "PYTHON_3123_PATH=C:\Users\RAIIN Studios\AppData\Local\Programs\Python\Python312\python.exe"
set "PYTHON_3123_BASE=C:\Users\RAIIN Studios\AppData\Local\Programs\Python\Python312"
if exist "%PYTHON_3123_PATH%" (
    echo Python 3.12.3 already installed at %PYTHON_3123_PATH%.
    set "SELECTED_PYTHON=%PYTHON_3123_PATH%"
    set "SELECTED_BASE=%PYTHON_3123_BASE%"
    goto :python_found
)

@REM Step 2: If Python 3.12.3 is not found, download and install it
echo Python 3.12.3 not found. Downloading and installing Python 3.12.3...
set "PYTHON_URL=https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe"
set "PYTHON_INSTALLER=python-3.12.3-amd64.exe"

@REM Download the installer using curl (Windows 10/11 includes curl by default)
curl -o "%PYTHON_INSTALLER%" "%PYTHON_URL%"
if errorlevel 1 (
    echo Failed to download Python 3.12.3. Please download it manually from https://www.python.org/downloads/release/python-3123/
    pause
    exit /b
)

@REM Install Python 3.12.3 silently with PATH and default directory
echo Installing Python 3.12.3...
"%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 TargetDir="%PYTHON_3123_BASE%"
if errorlevel 1 (
    echo Failed to install Python 3.12.3. Please install it manually from the downloaded file.
    pause
    exit /b
)

@REM Verify installation
if not exist "%PYTHON_3123_PATH%" (
    echo Python 3.12.3 installation failed or installed to a different location.
    pause
    exit /b
)

echo Python 3.12.3 installed successfully!
del "%PYTHON_INSTALLER%"
set "SELECTED_PYTHON=%PYTHON_3123_PATH%"
set "SELECTED_BASE=%PYTHON_3123_BASE%"

@REM Step 3: Locate other Python installations (optional fallback)
set "PYTHON_DIR=C:\Users\RAIIN Studios\AppData\Local\Programs\Python"
echo Scanning available Python installations...

set INDEX=0
for /d %%D in ("%PYTHON_DIR%\Python*") do (
    set /a INDEX+=1
    set "PYTHON_PATHS[!INDEX!]=%%D\python.exe"
    set "PYTHON_BASE[!INDEX!]=%%D"
    echo !INDEX!. %%D
)

echo Using Python 3.12.3 by default. Press Enter to continue, or select another version if desired.
set /p CHOICE=Enter the number of the Python version to use (or press Enter for Python 3.12.3):

if not defined CHOICE (
    goto :python_found
)

if not defined PYTHON_PATHS[%CHOICE%] (
    echo Invalid selection. Using Python 3.12.3...
    goto :python_found
)

set "SELECTED_PYTHON=!PYTHON_PATHS[%CHOICE%]!"
set "SELECTED_BASE=!PYTHON_BASE[%CHOICE%]!"

:python_found
echo Selected Python: %SELECTED_PYTHON%

@REM Step 4: Create a new virtual environment
set VENV_NAME=venv

echo Creating virtual environment "%VENV_NAME%" using %SELECTED_PYTHON%...
"%SELECTED_PYTHON%" -m venv %VENV_NAME%

if not exist "%VENV_NAME%" (
    echo Failed to create virtual environment.
    pause
    exit /b
)

@REM Step 5: Copy Include and Libs folders to the Venv (Triton)
echo Copying Include and Libs folders from %SELECTED_BASE% to %VENV_NAME%...
xcopy /E /I /Y "%SELECTED_BASE%\Include" "%VENV_NAME%\Include"
xcopy /E /I /Y "%SELECTED_BASE%\libs" "%VENV_NAME%\libs"

xcopy /E /I /Y "%SELECTED_BASE%\vcruntime140.dll" "%VENV_NAME%\Scripts\" 2>nul
xcopy /E /I /Y "%SELECTED_BASE%\vcruntime140_1.dll" "%VENV_NAME%\Scripts\" 2>nul

echo Virtual environment "%VENV_NAME%" created successfully!
echo Include, libs folders and VCRuntime DLLs copied.

call venv\Scripts\activate.bat
if errorlevel 1 (
    echo Failed to activate virtual environment.
    pause
    exit /b 1
)

echo.
echo Venv Activated and Checked
echo Next step: Install PyTorch
echo.

pause

@REM -------------------------------------------------------------------------------------------------
@REM Installing packages for the Venv and requirements for SageAttention including Pytorch
setlocal enabledelayedexpansion

python -m pip install --upgrade pip

@REM -------------------------------------------------------------------------------------------------
@REM Checking for installed CUDA version and installing latest relevant Pytorch for it
setlocal enabledelayedexpansion

@REM Step 1: Get the CUDA version using nvcc --version
for /f "tokens=5 delims= " %%A in ('nvcc --version ^| findstr /C:"release"') do (
    for /f "tokens=1 delims=," %%B in ("%%A") do set cuda_version=%%B
)

@REM Step 2: Extract major version
for /f "tokens=1 delims=." %%a in ("%cuda_version%") do set cuda_major=%%a

@REM Step 3: Extract minor version
for /f "tokens=2 delims=." %%b in ("%cuda_version%") do set cuda_minor=%%b

set cuda_version=!cuda_major!.!cuda_minor!

echo.
echo Detected CUDA Version: %cuda_version%
echo.

@REM Step 4: Remove the dot from CUDA version (convert v12.8 → 128)
set "CLEAN_CUDA=%cuda_version:.=%"

@REM Step 5: Set PyTorch URLs
set "STABLE_URL=https://download.pytorch.org/whl/cu%CLEAN_CUDA%"
set "NIGHTLY_URL=https://download.pytorch.org/whl/nightly/cu%CLEAN_CUDA%"

@REM Step 6: Ask User for Stable or Nightly Build
echo.
echo CUDA 12.8 is now supported with PyTorch 2.8+ and SageAttention3
echo Choose PyTorch build:
echo [1] PyTorch 2.8.0 (Recommended for CUDA 12.8 + Blackwell)
echo [2] Nightly (Latest development build)
set /p CHOICE="Enter choice (1 or 2): "

if "%CHOICE%"=="1" (
    set "PYTORCH_BUILD=2.8.0"
    set "PYTORCH_URL=%STABLE_URL%"
) else if "%CHOICE%"=="2" (
    set "PYTORCH_BUILD=Nightly"
    set "PYTORCH_URL=%NIGHTLY_URL%"
) else (
    echo Invalid choice. Defaulting to PyTorch 2.8.0.
    set "PYTORCH_BUILD=2.8.0"
    set "PYTORCH_URL=%STABLE_URL%"
)

@REM Step 7: Install PyTorch
echo.
echo Installing PyTorch %PYTORCH_BUILD% with CUDA %cuda_version%...
echo.

if "%PYTORCH_BUILD%"=="2.8.0" (
    pip install torch==2.8.0 torchvision torchaudio --index-url %PYTORCH_URL%
) else (
    pip install --pre torch torchvision torchaudio --index-url %PYTORCH_URL%
)

echo PyTorch %PYTORCH_BUILD% installation complete.

@REM Step 8: Verify installation
echo.
echo Verifying PyTorch installation...
echo.

python -c "import torch; print(f'PyTorch Version: {torch.__version__}, CUDA Available: {torch.cuda.is_available()}, CUDA Version: {torch.version.cuda}')" 
if !errorlevel! NEQ 0 (
    echo.
    echo PyTorch installation failed. Please check for errors above.
    pause
    exit /b
)

@REM Step 9: Install the rest of the requirements for the Venv, Triton and SageAttention
pip install -r requirements.txt
pip install onnxruntime-gpu
pip install wheel
pip install setuptools
pip install packaging
pip install ninja
pip install "accelerate>=1.1.1"
pip install "diffusers>=0.31.0"
pip install "transformers>=4.39.3"
python -m ensurepip --upgrade
python -m pip install --upgrade setuptools

echo.
echo Successfully installed Requirements for the Venv, Triton and SageAttention
echo Next step: Install Triton
echo.
pause

@REM --------------------------------------------------------------------------------------------------
@REM Install Triton Wheel for Triton & install
setlocal enabledelayedexpansion

@REM Step 1: Determine Python Major and Minor Version and display it to User
for /f "tokens=2 delims= " %%i in ('python --version') do (
    set py_version=%%i
)
for /f "tokens=1,2 delims=." %%a in ("!py_version!") do (
    set py_major_version=%%a
    set py_minor_version=%%b
)

@REM Step 2: Display the Installed Python Version
echo Detected Python Version: !py_major_version!.!py_minor_version!

@REM Step 3: Detect PyTorch version using Python
for /f "delims=" %%A in ('python -c "import torch; print(torch.__version__)" 2^>nul') do set "PYTORCH_VERSION=%%A"

@REM Step 4: Extract major and minor version (e.g., 2.5 from 2.5.1)
for /f "tokens=1,2 delims=." %%B in ("%PYTORCH_VERSION%") do (
    set "PYTORCH_MAJOR=%%B"
    set "PYTORCH_MINOR=%%C"
    set "PYTORCH_VERSION_SHORT=%%B.%%C"
)

@REM Step 5: Check if PyTorch is installed
if not defined PYTORCH_VERSION (
    echo ERROR: PyTorch is not installed. Please install PyTorch first.
    pause
    exit /b
)

echo Detected PyTorch version: %PYTORCH_VERSION_SHORT%

@REM Step 6: Restrict Triton versions based on PyTorch version
if "%PYTORCH_MAJOR%"=="2" (
    if "%PYTORCH_MINOR%" GEQ "6" (
        echo PyTorch 2.6+ detected. All Triton versions available.
        set "OPTION1=1 - Triton 3.2.0"
        set "OPTION2=2 - Triton 3.1.0"
    ) else if "%PYTORCH_MINOR%" GEQ "4" (
        echo PyTorch 2.4 or 2.5 detected. Triton 3.2.0 is not supported.
        set "OPTION1="
        set "OPTION2=2 - Triton 3.1.0"
    ) else (
        echo WARNING: PyTorch %PYTORCH_VERSION_SHORT% is too old! Triton 3.1.0 and 3.2.0 require PyTorch 2.4+.
        echo Only Triton 3.0.0 is available, unsure if it will work.
        set "OPTION1="
        set "OPTION2="
    )
) else (
    echo ERROR: PyTorch version not supported. Only PyTorch 2.x is allowed.
    pause
    exit /b
)

set "OPTION3=3 - Triton 3.0.0"

@REM Step 7: Display options
echo Select the package you want to download: 
if defined OPTION1 echo %OPTION1%
if defined OPTION2 echo %OPTION2%
if defined OPTION3 echo %OPTION3%

@REM Step 8: Get user choice
set /p CHOICE=Enter your choice: 

@REM Step 9: Validate selection
if "%CHOICE%"=="1" if not defined OPTION1 echo Invalid choice. Exiting. & exit /b
if "%CHOICE%"=="2" if not defined OPTION2 echo Invalid choice. Exiting. & exit /b
if "%CHOICE%"=="3" if not defined OPTION3 echo Invalid choice. Exiting. & exit /b

echo You selected Triton %CHOICE%.
if "%CHOICE%"=="1" echo Note: Triton 3.2.0 works best with PyTorch 2.6+. Upgrade recommended!

@REM Step 10: Map Python versions to corresponding wheel URLs
set WHEEL_URL=

if "%CHOICE%"=="1" (
    if "!py_major_version!.!py_minor_version!"=="3.10" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.2.0-windows.post10/triton-3.2.0-cp310-cp310-win_amd64.whl
    if "!py_major_version!.!py_minor_version!"=="3.12" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.2.0-windows.post10/triton-3.2.0-cp312-cp312-win_amd64.whl
    if "!py_major_version!.!py_minor_version!"=="3.13" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.2.0-windows.post10/triton-3.2.0-cp313-cp313-win_amd64.whl
)

if "%CHOICE%"=="2" (
    if "!py_major_version!.!py_minor_version!"=="3.10" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post9/triton-3.1.0-cp310-cp310-win_amd64.whl
    if "!py_major_version!.!py_minor_version!"=="3.11" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post9/triton-3.1.0-cp311-cp311-win_amd64.whl
    if "!py_major_version!.!py_minor_version!"=="3.12" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post9/triton-3.1.0-cp312-cp312-win_amd64.whl
)

if "%CHOICE%"=="3" (
    if "!py_major_version!.!py_minor_version!"=="3.10" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post9/triton-3.0.0-cp310-cp310-win_amd64.whl
    if "!py_major_version!.!py_minor_version!"=="3.11" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post9/triton-3.0.0-cp311-cp311-win_amd64.whl
    if "!py_major_version!.!py_minor_version!"=="3.12" set WHEEL_URL=https://github.com/woct0rdho/triton-windows/releases/download/v3.1.0-windows.post9/triton-3.0.0-cp312-cp312-win_amd64.whl
)

@REM Step 11: Validate and download the selected wheel
if "%WHEEL_URL%"=="" (
    echo No compatible wheel found for Python %py_major_version%.%py_minor_version% or invalid choice.
    exit /b
)

echo Installing Triton package for Python %py_major_version%.%py_minor_version%...
pip install %WHEEL_URL%

@REM Step 12: Deleting Triton's cached files as these can make it fault
setlocal

set "TRITON_CACHE=C:\Users\RAIIN Studios\.triton\cache"
set "TORCHINDUCTOR_CACHE=C:\Users\RAIIN Studios\AppData\Local\Temp\torchinductor_RAIIN Studios\triton"

if exist "%TRITON_CACHE%" (
    echo Deleting .triton cache...
    rmdir /s /q "%TRITON_CACHE%" 2>nul
    mkdir "%TRITON_CACHE%"
    echo .Triton cache cleared.
) else (
    echo .Triton cache folder not found.
)

if exist "%TORCHINDUCTOR_CACHE%" (
    echo Deleting torchinductor cache...
    rmdir /s /q "%TORCHINDUCTOR_CACHE%" 2>nul
    mkdir "%TORCHINDUCTOR_CACHE%"
    echo Torchinductor cache cleared.
) else (
    echo Torchinductor cache folder not found.
)

echo.
echo Successfully installed Triton and caches cleared
echo Make a coffee and ignore various error comments whilst SageAttention compiles when you press enter this time
echo.
pause

@REM --------------------------------------------------------------------------------------------------
@REM Install SageAttention3 with Blackwell optimization

cd venv
git clone https://github.com/thu-ml/SageAttention
cd SageAttention

echo.
echo Setting Blackwell-specific compilation flags for SageAttention3...
echo.

@REM Set environment variables for Blackwell (sm_120) compilation
set EXT_PARALLEL=4
set NVCC_APPEND_FLAGS=--threads 8 -gencode arch=compute_120,code=sm_120
set MAX_JOBS=4
set TORCH_CUDA_ARCH_LIST=12.0

echo Compiling SageAttention3 for NVIDIA Blackwell architecture...
echo This may take several minutes. Please be patient...
echo.

python.exe -m pip install .
@REM Using pip install instead of setup.py for better dependency handling

@REM Cleaning up SageAttention source
cd ..
rmdir /s /q SageAttention
echo Successfully installed SageAttention3 with Blackwell optimization and cleared up source files
echo.

pause

@REM --------------------------------------------------------------------------------------------------
@REM Make a start bat file for Comfy
setlocal

cd ..
cd ..

@REM Step 1: Define the path for the new batch file
set "new_batch_file=Run_Comfyui.bat"

@REM Step 2: Create the new Comfy startup batch file
(
echo @echo off
echo cd "C:\Users\RAIIN Studios\Documents\Comfy_Blackwell\Comfy_new\ComfyUI"
echo call venv\Scripts\activate.bat
echo echo Venv Activated
echo .\venv\Scripts\python.exe -s main.py --fast --windows-standalone-build --use-sage-attention
echo pause
) > "%new_batch_file%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file%" (
    echo The file %new_batch_file% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file%.
)

@REM --------------------------------------------------------------------------------------------------
@REM Create a batch file to auto open a CMD window and activate the Venv
@REM Step 1: Define the path for the new batch file
set "new_batch_file2=Activate_Venv.bat"

@REM Step 2: Create the new batch file with the specified content
(
echo @echo off
echo cd "C:\Users\RAIIN Studios\Documents\Comfy_Blackwell\Comfy_new\ComfyUI\venv"
echo call .\Scripts\activate.bat
echo echo Venv Activated
echo cmd.exe /k
) > "%new_batch_file2%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file2%" (
    echo The file %new_batch_file2% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file2%.
)

@REM --------------------------------------------------------------------------------------------------
@REM Create a batch file to update Comfy via git pull
@REM Step 1: Define the path for the new batch file
set "new_batch_file3=Update_Comfy.bat"

@REM Step 2: Create the new batch file with the specified content
(
echo @echo off
echo cd "C:\Users\RAIIN Studios\Documents\Comfy_Blackwell\Comfy_new\ComfyUI"
echo git pull
echo pause
) > "%new_batch_file3%"

@REM Step 3: Check if the new batch file was created successfully
if exist "%new_batch_file3%" (
    echo The file %new_batch_file3% has been created successfully.
) else (
    echo Failed to create the file %new_batch_file3%.
)

echo.
echo Three bat files saved to install folder 
echo   1. ComfyUI start 
echo   2. Activate the venv for manual input 
echo   3. Update via git pull
echo. 
echo Next Step: Install Comfy Manager and optionally kijai/Wan-HunyuanVideoWrapper
pause

@REM --------------------------------------------------------------------------------------------------
@REM Installing Comfy Manager rather than faffing around

cd "C:\Users\RAIIN Studios\Documents\Comfy_Blackwell\Comfy_new\ComfyUI\custom_nodes"

git clone https://github.com/ltdrdata/ComfyUI-Manager.git

echo Successfully cloned ComfyUI-Manager

@REM Step 1: Define the repository URL and the target folder
set REPO_URL=https://github.com/kijai/ComfyUI-WanVideoWrapper.git

@REM Step 2: Prompt the user for confirmation
echo Do you want to clone Kijai's Wan repository from %REPO_URL% into ComfyUI ? 
set /p USER_CONFIRMATION=Type Y [yes] or N [no]: 

@REM Step 3: Convert input to uppercase to handle both lowercase and uppercase inputs
set USER_CONFIRMATION=%USER_CONFIRMATION:~0,1%
if /i "%USER_CONFIRMATION%"=="Y" (
    echo Cloning repository...
    git clone "%REPO_URL%"
    if errorlevel 1 (
        echo An error occurred while cloning the repository.
    ) else (
        echo kijai's ComfyUI-HunyuanVideoWrapper repository cloned successfully.
    )
) else (
    echo Clone operation cancelled by user.
)

echo.
echo Copy across your extra_model_paths.yaml file now start ComfyUI.
echo CMD window left open with Venv still activated for anything you wish to manually install into Custom_Nodes

endlocal
pause
cmd.exe /k