# VoxStudy

Prototipo de aplicación para iPhone que permite escuchar apuntes escritos y texto extraído de archivos PDF. Desarrollado en Swift con SwiftUI para demostrar el uso de **AVSpeechSynthesizer** en la asignatura ETPS4 de la Universidad Tecnológica de El Salvador.

## Funciones

- Escribir o pegar texto y asignarle un título opcional.
- Importar un PDF con texto extraíble y revisar el contenido en el editor.
- Escuchar, pausar, continuar y detener la narración.
- Resaltar el fragmento narrado y repasar el contenido por párrafos.
- Repetir un párrafo o pasar al anterior o al siguiente.
- Elegir voces en español o inglés, según las disponibles en el dispositivo.
- Ajustar velocidad, tono y volumen.
- Elegir apariencia clara, oscura o del sistema.
- Probar textos integrados y un PDF de ejemplo.
- Conservar las preferencias de narración, idiomas y apariencia entre ejecuciones.
- Preparar la traducción entre español e inglés antes de narrar cuando los idiomas de origen y salida son distintos.

## Tecnologías

| Tecnología | Uso en VoxStudy |
| --- | --- |
| Swift y SwiftUI | Lógica, pantallas, navegación y estado de la interfaz. |
| AVFoundation y AVSpeechSynthesizer | Síntesis de voz y controles de reproducción. |
| PDFKit | Extracción de texto de los PDF. |
| Translation | Traducción entre español e inglés. |
| UIKit | Presentación y resaltado del texto de lectura. |
| UserDefaults y AppStorage | Persistencia de preferencias. |

AVSpeechSynthesizer es la clase central del tema investigado. La traducción se realiza por separado mediante Translation; cambiar únicamente la voz no traduce el contenido.

## Requisitos

- Una Mac con Xcode y los componentes de iOS correspondientes.
- **El proyecto publicado tiene el destino mínimo configurado en iOS 26.5.** El simulador o dispositivo seleccionado debe cumplir ese mínimo.
- No se requieren paquetes externos ni claves de API.

Entorno utilizado durante el desarrollo: **iMac con Apple M4, macOS Tahoe 26.4, Xcode 26.6 y simulador iPhone 17 Pro con iOS 26.5**.

## Cómo ejecutar el proyecto

1. Clona este repositorio o descárgalo desde **Code → Download ZIP** y descomprímelo.
2. Desde la raíz del repositorio, abre **`VoxStudy/VoxStudy.xcodeproj`** en Xcode.
3. Selecciona el esquema **VoxStudy** y un simulador de iPhone compatible.
4. Presiona **Command + R** para compilar y ejecutar.
5. Entra a **Lector**, escribe un texto o carga uno desde **Ejemplos** y configura los idiomas.

Para instalar en un iPhone físico, también se necesita configurar la firma del proyecto con una cuenta Apple, seleccionar el dispositivo y activar su modo de desarrollador.

## Lectura e idiomas

El usuario indica manualmente el idioma original en **Texto en** y el idioma de salida en **Leer en**.

| Texto en | Leer en | Comportamiento previsto |
| --- | --- | --- |
| Español | Español | Leer el texto original con voz española. |
| Inglés | Inglés | Leer el texto original con voz inglesa. |
| Español | Inglés | Traducir al inglés y narrar el resultado. |
| Inglés | Español | Traducir al español y narrar el resultado. |

Cuando se traduce, el lector recibe el resultado y el editor conserva el original. Cancelar o recibir un error de traducción no inicia la narración del resultado.

### Estado de la traducción

La traducción está implementada, pero su funcionamiento efectivo **queda pendiente de validación en un entorno compatible**. Las APIs de Translation no funcionan en el simulador de iOS.

En el simulador se puede comprobar la lectura directa usando el mismo idioma en ambas opciones. Si se eligen idiomas distintos, VoxStudy muestra un aviso y conserva el texto. Para probar el flujo completo de traducción se necesita un dispositivo compatible; la primera vez puede requerirse conexión para descargar los modelos de idioma.

## Archivos principales

Los archivos Swift se encuentran en **`VoxStudy/VoxStudy/`**, desde la raíz del repositorio.

| Archivo o grupo | Responsabilidad |
| --- | --- |
| `VoxStudyApp.swift` y `ContentView.swift` | Entrada de la aplicación y coordinación de pantallas. |
| `HomeView.swift`, `ReaderView.swift` y `ExamplesView.swift` | Inicio, editor, lector y ejemplos. |
| `SettingsView.swift` | Preferencias de narración y apariencia. |
| `SpeechManager.swift` | Reproducción, párrafos y eventos de resaltado. |
| `ReaderSession.swift` | Texto original, título y metadatos del PDF. |
| `PDFImportService.swift` y `ParagraphParser.swift` | Extracción y organización del texto. |
| `ReadingLanguage.swift` y `TranslationReadingSheet.swift` | Idiomas admitidos y proceso de traducción. |
| `ReadingTextView.swift` | Texto de lectura y resaltado. |
| `AppTheme.swift`, `AppHeader.swift` y `ExampleCard.swift` | Colores y componentes compartidos. |
| `StudyExample.swift` y `VoxStudy_Prueba.pdf` | Material de demostración. |

## Alcance y limitaciones

- Se admiten español e inglés, con un idioma por documento y selección manual del idioma original.
- Los PDF deben contener texto extraíble y poder abrirse sin contraseña. No se incluye OCR para documentos escaneados.
- Las tablas y las páginas con varias columnas pueden producir un orden de lectura diferente al visual; el texto puede corregirse en el editor.
- No se importan archivos Word ni se exportan archivos de audio.
- El texto de trabajo y la traducción se conservan durante la sesión; no hay una biblioteca permanente de documentos.
- La versión actual guarda preferencias. La integración con la base de datos mencionada en la guía académica queda pendiente de recibir ese recurso.

## Pruebas

Se reportó funcionamiento en el simulador de la lectura directa en español e inglés, la importación de PDF, la pausa y los ajustes de narración. La traducción entre idiomas permanece pendiente de validación real. Estas pruebas corresponden a un prototipo académico.

## Autor

**Kevin Humberto Umanzor de la Paz**  
Universidad Tecnológica de El Salvador  
Asignatura: Normas y Estándares Internacionales ETPS4

## Demostración

El enlace del video de YouTube se incorporará después de su publicación.

## Referencias

- [AVSpeechSynthesizer](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer)
- [PDFKit](https://developer.apple.com/documentation/pdfkit)
- [Translation](https://developer.apple.com/documentation/translation)
