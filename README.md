# punto_venta_app

Aplicación de Punto de Venta (POS) desarrollada en Flutter con arquitectura BLoC.

---

## Configuración de Referencia
Esta es la versión exacta de los entornos en los que esta app se compila:

*   **SDK de Flutter:** `3.27.2` (Canal `stable`)
*   **SDK de Dart:** `3.6.1`
*   **Visual Studio:** `Visual Studio Community 2022 17.14.29` (con compilador MSVC `14.44.35207` / toolset `v143`)
*   **Visual Studio Build Tools 2019:** `16.11.54` (con compilador MSVC `14.29.30133` / toolset `v142`)
*   **Windows SDK:** `10.0.26100.0`
*   **Android Studio:** `2025.2.1` (Para desarrollo Android)

---

## Configuración

### 1. Requisitos del Sistema (Compilación para Windows)
Flutter requiere el compilador de C++ de Visual Studio para compilar aplicaciones de escritorio nativas.

1. Descarga e instala **[Visual Studio Community 2022](https://visualstudio.microsoft.com/es/vs/)**.
2. Durante el proceso de instalación, en la pestaña de **Cargas de trabajo (Workloads)**, selecciona obligatoriamente:
   * **Desarrollo para el escritorio con C++** *(Desktop development with C++)*.
3. Asegúrate de que los siguientes componentes opcionales estén marcados (se seleccionan por defecto):
   * MSVC v143 - Herramientas de compilación de C++ para VS 2022 x64/x86.
   * Herramientas de CMake de C++ para Windows.
   * SDK de Windows 10 (o Windows 11).

---

### 2. Configurar el SDK de Flutter (Usando FVM)
Este proyecto utiliza **FVM (Flutter Version Management)** para asegurar que todos usen la misma versión exacta de Flutter (`3.27.2`).

1. Abre tu terminal e instala FVM globalmente (requiere tener Dart o Node.js instalado):
   * **Vía Dart:**
     ```powershell
     dart pub global activate fvm
     ```
   * **Vía NPM:**
     ```powershell
     npm install -g fvm
     ```
2. Clona el proyecto y sitúate en la raíz del mismo.
3. Descarga la versión exacta de Flutter configurada y vincula el entorno ejecutando:
   ```powershell
   fvm install
   fvm use 3.27.2 --force
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

