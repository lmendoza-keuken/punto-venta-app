class AuthHtmlTemplates {
  static const String successPage = '''
<!DOCTYPE html>
<html>
  <head>
    <title>Inicio de sesión completado</title>
    <meta charset="utf-8">
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        background-color: #f3f4f6;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        margin: 0;
      }
      .card {
        background: white;
        padding: 2.5rem;
        border-radius: 16px;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        text-align: center;
        max-width: 420px;
        width: 90%;
      }
      .icon {
        font-size: 48px;
        color: #10b981;
        margin-bottom: 1rem;
      }
      h1 {
        color: #1f2937;
        font-size: 22px;
        margin-bottom: 0.75rem;
        font-weight: 700;
      }
      p {
        color: #4b5563;
        line-height: 1.6;
        font-size: 15px;
        margin-bottom: 0;
      }
    </style>
  </head>
  <body>
    <div class="card">
      <div class="icon">✓</div>
      <h1>¡Inicio de sesión exitoso!</h1>
      <p>Ya puedes cerrar esta pestaña y regresar a la aplicación de Facturador para continuar.</p>
    </div>
  </body>
</html>
''';

  static String getErrorPage(String message) => '''
<!DOCTYPE html>
<html>
  <head>
    <title>Error de inicio de sesión</title>
    <meta charset="utf-8">
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        background-color: #f3f4f6;
        display: flex;
        justify-content: center;
        align-items: center;
        height: 100vh;
        margin: 0;
      }
      .card {
        background: white;
        padding: 2.5rem;
        border-radius: 16px;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        text-align: center;
        max-width: 420px;
        width: 90%;
      }
      .icon {
        font-size: 48px;
        color: #ef4444;
        margin-bottom: 1rem;
      }
      h1 {
        color: #1f2937;
        font-size: 22px;
        margin-bottom: 0.75rem;
        font-weight: 700;
      }
      p {
        color: #4b5563;
        line-height: 1.6;
        font-size: 15px;
        margin-bottom: 0;
      }
    </style>
  </head>
  <body>
    <div class="card">
      <div class="icon">✗</div>
      <h1>Error al iniciar sesión</h1>
      <p>$message</p>
    </div>
  </body>
</html>
''';
}
