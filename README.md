# punto_venta_app

Aplicación de Punto de Venta (POS) desarrollada en Flutter con arquitectura BLoC.

---

## Configuración de Referencia
Esta es la versión exacta de los entornos en los que esta app se compila:

*   **SDK de Flutter:** `3.38.3` (Canal `stable`)
*   **SDK de Dart:** `3.7.0`
*   **Visual Studio:** `Visual Studio Community 2026` (con compilador MSVC para VS 2026)
*   **Windows SDK:** `10.0.26100.0` o superior
*   **Android Studio:** `2025.2.1` (Para desarrollo Android)

---

## Configuración

### 1. Requisitos del Sistema (Compilación para Windows)
Flutter requiere el compilador de C++ de Visual Studio para compilar aplicaciones de escritorio nativas.

1. Descarga e instala **[Visual Studio Community 2026](https://visualstudio.microsoft.com/es/vs/)**.
2. Durante el proceso de instalación, en la pestaña de **Cargas de trabajo (Workloads)**, selecciona obligatoriamente:
   * **Desarrollo para el escritorio con C++** *(Desktop development with C++)*.
3. Asegúrate de que los siguientes componentes opcionales estén marcados (se seleccionan por defecto):
   * MSVC - Herramientas de compilación de C++ para VS 2026 x64/x86.
   * Herramientas de CMake de C++ para Windows.
   * SDK de Windows 10 (o Windows 11).

> [!IMPORTANT]
> **Solución a errores comunes de compilación en Windows:**
> * **Error de descompresión del SDK de Firebase (`ZIP decompression failed`):**
>   Para evitar fallos de descompresión automática de Firebase en Windows, descarga manualmente el SDK de Firebase C++ v12.0.0 desde [aquí](https://github.com/firebase/firebase-cpp-sdk/releases/download/v12.0.0/firebase_cpp_sdk_windows_12.0.0.zip), descomprímelo (ej: en `C:\Tools\firebase_cpp_sdk_windows`) y añade una variable de entorno de usuario llamada `FIREBASE_CPP_SDK_DIR` apuntando a esa carpeta:
>   ```powershell
>   [Environment]::SetEnvironmentVariable("FIREBASE_CPP_SDK_DIR", "C:\Tools\firebase_cpp_sdk_windows", "User")
>   ```
>   *(Reinicia tu terminal tras ejecutar el comando para aplicar los cambios).*

---

### 2. Configurar el SDK de Flutter (Usando FVM)
Este proyecto utiliza **FVM (Flutter Version Management)** para asegurar que todos usen la misma versión exacta de Flutter (`3.38.3`).

1. Abre tu terminal e instala FVM (se recomienda la instalación **standalone** para evitar errores con la herramienta `dart` global):
   * **Vía Chocolatey:**
     ```powershell
     choco install fvm
     ```
   * **Vía Scoop:**
     ```powershell
     scoop bucket add flutter
     scoop install fvm
     ```
   * **Vía Dart (si ya tienes Dart en el PATH):**
     ```powershell
     dart pub global activate fvm
     ```
2. Clona el proyecto y sitúate en la raíz del mismo.
3. Descarga la versión exacta de Flutter configurada y vincula el entorno ejecutando:
   ```powershell
   fvm install
   fvm use 3.38.3 --force
   ```

> [!NOTE]
> Esto creará o actualizará la carpeta `.fvm/flutter_sdk` apuntando al SDK correcto en tu máquina local.

---

### 3. Instalación de Dependencias y Generación de Código
Antes de ejecutar el proyecto por primera vez o al actualizarlo:

1. Obtén las dependencias de Flutter:
   ```powershell
   fvm flutter pub get
   ```
2. Genera los archivos serializables y de inyección de dependencias (Freezed, Retrofit, etc.):
   ```powershell
   fvm flutter pub run build_runner build --delete-conflicting-outputs
   ```

