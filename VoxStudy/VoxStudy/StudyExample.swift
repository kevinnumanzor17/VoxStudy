import Foundation

enum ExampleTone {
    case peach
    case sage
    case lilac
}

struct StudyExample: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let tone: ExampleTone
    var language: ReadingLanguage = .spanish
    let text: String

    static let all: [StudyExample] = [
        StudyExample(
            id: "study",
            title: "Métodos de estudio",
            subtitle: "Organizá tus sesiones y repasá por partes.",
            symbol: "books.vertical.fill",
            tone: .peach,
            text: """
            Organizá tus apuntes por temas y elegí una idea principal para cada sesión. Antes de empezar, prepará el material que vas a utilizar.

            Leé un párrafo, pausá la narración y explicá con tus propias palabras lo que entendiste. Repetí las partes que necesiten más atención.

            Al terminar, anotá preguntas sobre el tema y revisá las respuestas en tus apuntes. Podés volver a escuchar los párrafos que quieras repasar.
            """
        ),
        StudyExample(
            id: "solar",
            title: "Sistema solar",
            subtitle: "Un recorrido breve por nuestros planetas.",
            symbol: "globe.americas.fill",
            tone: .sage,
            text: """
            El Sistema Solar está formado por el Sol y los cuerpos que orbitan a su alrededor. Entre ellos se encuentran los planetas, sus satélites, los asteroides y los cometas.

            Los ocho planetas, en orden desde el Sol, son Mercurio, Venus, Tierra, Marte, Júpiter, Saturno, Urano y Neptuno.

            Imaginá un recorrido que comienza cerca del Sol y avanza hacia los planetas más lejanos. Podés repetir este párrafo o volver al anterior para repasar sus nombres.
            """
        ),
        StudyExample(
            id: "story",
            title: "Una breve historia",
            subtitle: "Probá la narración con un pequeño relato.",
            symbol: "sparkles",
            tone: .lilac,
            text: """
            Una mañana, Lucía encontró un cuaderno junto a la ventana de la biblioteca. En la primera página había una frase: cada historia comienza con una pregunta.

            Lucía abrió el cuaderno y escribió qué le gustaría aprender durante aquel día. Después eligió un libro y buscó un lugar tranquilo para leer.

            Al volver a casa, descubrió que su cuaderno ya tenía nuevas ideas. Sonrió y dejó una página en blanco para la historia del día siguiente.
            """
        ),
        StudyExample(
            id: "english",
            title: "Lectura en inglés",
            subtitle: "Escuchá en inglés o traducí al español.",
            symbol: "globe",
            tone: .sage,
            language: .english,
            text: """
            Reading a little every day can help you build a useful study habit. Choose a quiet place and focus on one topic at a time.

            After each paragraph, pause and explain the main idea in your own words. You can listen again when you need to review.

            Before you finish, write down one question and look for the answer in your notes.
            """
        )
    ]
}


